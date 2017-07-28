create or replace package body                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     stp_payment_pkg as
    
    
    /**********************************************************************
    /*
    /* @procedire: process_checked_fields
    /*
    /* @description: finds every field that was checked by the user and 
    /* inserts/ updates the STP_PAYMENT_ITEMS table accordingly
    /*
    /**********************************************************************/ 

    procedure process_checked_fields
    as
      l_exist varchar2(32000);
      l_temp1 number;
      l_temp2 number;
    begin 
        sys.dbms_output.enable;
        for i in 1..APEX_APPLICATION.G_F01.COUNT loop
            
            select count(*) into l_temp1 from bsmart_data.STP_PAYMENT_ITEMS STPPI 
            where STPPI.TREEID||'-'||STPPI.ACTIVITY_TYPE = APEX_APPLICATION.G_F01(i);
            
            if l_temp1 != 0 then
              select TREEID||'-'||ACTIVITY_TYPE into l_exist from bsmart_data.STP_PAYMENT_ITEMS STPPI 
              where STPPI.TREEID||'-'||STPPI.ACTIVITY_TYPE = APEX_APPLICATION.G_F01(i);
            end if;
            
            sys.dbms_output.put_line(l_exist || 'test');
                apex_debug.log_dbms_output;
            
            case when APEX_APPLICATION.G_F01(i) = l_exist then
                select PAYMENT_STATUS into l_temp2 from bsmart_data.STP_PAYMENT_ITEMS STPPI
                where STPPI.TREEID||'-'||STPPI.ACTIVITY_TYPE = APEX_APPLICATION.G_F01(i);
                
                if l_temp2 = 1 then
                update STP_PAYMENT_ITEMS STPPI set PAYMENT_STATUS = 0 
                where STPPI.TREEID||'-'||STPPI.ACTIVITY_TYPE = APEX_APPLICATION.G_F01(i);
                else
                update STP_PAYMENT_ITEMS STPPI set PAYMENT_STATUS = 1 
                where STPPI.TREEID||'-'||STPPI.ACTIVITY_TYPE = APEX_APPLICATION.G_F01(i);
                end if;
            else
            insert into STP_PAYMENT_ITEMS(TREEID, ACTIVITY_TYPE, PAYMENT_STATUS)
            select distinct TREEID, ACTIVITY_TYPE_ID, 1 from STP_DEFICIENCY_V
            where TREEID||'-'||ACTIVITY_TYPE_ID = APEX_APPLICATION.G_F01(i);
            end case;
            
        end loop;
        
    end;
    
    /**********************************************************************
    /*
    /* @procedure: process_payment
    /*
    /* @description: When the pay button is pressed, sets all the items to 
    /* paid where they were previously set to assign for payment
    /*
    /**********************************************************************/ 
    
    procedure process_payment
    as
      
    begin
      update bsmart_data.STP_PAYMENT_ITEMS
      set PAYMENT_STATUS = 2,
      PAYMENT_CERT_NO = (select max(nvl(PAYMENT_CERT_NO,0)) + 1 from bsmart_data.STP_PAYMENT_ITEMS)
      where PAYMENT_STATUS = 1;
    end;
    
    /**********************************************************************
    /*
    /* @procedure: create_deficiency_snapshot
    /*
    /* @description: creates a snapshot in time of the current deficiencies
    /*
    /* @type p_year In number - the year the snapshot was created for
    /*
    /**********************************************************************/ 
    
    procedure create_deficiency_snapshot(p_year in number)
    as
      l_seq number;
    begin
      select nvl(max(SEQ_ID) + 1, 1) into l_seq from STP_DEFICIENCY_LIST_SNAPSHOTS where CURRENTYEAR = p_year;  
      
      insert into STP_DEFICIENCY_LIST_SNAPSHOTS STPDLS(SEQ_ID, CURRENTYEAR, TREEID, TAGNUMBER, ITEM, HEALTH, DEF, REP, CONTRACTITEM, MUNICIPALITY, ROADSIDE)
      select distinct
        l_seq,
        p_year,
        STPDV.TREEID,
        STPDV.TAGNUMBER,
        d.ITEM,
        d.HEL,
        d.DEF,
        'repair',--d.REP,
        d.CON,
        d.MUN,
        d.RD
     from STP_DEFICIENCY_V STPDV
     join (
      select distinct 
              s.TREEID as "TID",
              s.STOCK_TYPE ||' - '|| s.PLANT_TYPE ||' - '|| t.SPECIES as "ITEM",
              t.CURRENTTREEHEALTH as "HEL",
              t.SIDEOFSTREET as "RD",
              s.CONTRACTITEM as "CON",
              t.MUNICIPALITY as "MUN",
              s.DEFICIENCY as "DEF"          
       from (
        select * from
        STP_DEFICIENCY_V 
       )  
       UNPIVOT include nulls(
        MATCH
        for DEFICIENCY
        IN (CROWNDIEBACK, CROWNINSECTDISEASE, EPICORMICBRANCHING, BRANCHINGSTRUCTURE,
        ROOTBALLSIZE, ROOTBALLLOOSE, GIRDLINGROOTS, STEMINSECTDISEASE, STEMTISSUENECROSIS,
        STEMSCARS, GIRDLEDSTEM, PLANTINGHOLESIZE, BACKFILL, PLANTINGLOW, PLANTINGHIGH,
        SOILRETENTIONRING, BURLAPWIREROPE, BEDPREPARATIONDIAMETER, BEDPREPARATIONSOD,
        BEDPREPARATIONCULTIVATION, BEDPREPARATIONCULTIVATIONDEPTH, MULCHDEPTH, MULCHDIAMETER,
        MULCHRING, MULCHSTEM, STEMCROWNROPE, TREEGATORBAG, TREEGUARD, PRUNING, STAKING, 
        EXTRATREE, INCORRECTLOCATION, UNAPPROVEDSPECIES, INCORRECTSIZE, MISSINGTREE)
       ) s
       join transd.fsttree@etrans t on s.TREEID = t.TREEID
       where MATCH = 1
       and s.OBJECTID = (select max(OBJECTID) from STP_DEFICIENCY_V
       where TREEID = s.TREEID)
       and s.CONTRACTOPERATION = 1 and s.activity_type_id<>2
       and s.CONTRACTYEAR = p_year
       order by s.TREEID
     ) d on STPDV.TREEID = d.TID
     where STPDV.CONTRACTYEAR = p_year; 
    end;
    
    /**********************************************************************
    /*
    /* @procedure: delete_snapshot
    /*
    /* @description: deletes the currently selected snapshot
    /*
    /* @type p_snap In number - the snapshot version number to be deleted
    /*
    /**********************************************************************/ 
    
    procedure delete_snapshot(p_snap in number)
    as
    begin
      delete from STP_DEFICIENCY_LIST_SNAPSHOTS 
      where SEQ_ID = p_snap;
      commit;
    end;
    
    -- won't comment for now, moving to aop_factory eventually
    function AOP_payment_report return varchar2
    as
    l_return clob;
    begin
      l_return := q'[
                  with status as (
  select TREEID as "TREEID", READY_STATUS as "STATUS" from STP_DEFICIENCY_V STPD2
  where CREATEDATE = (select max(CREATEDATE) from STP_DEFICIENCY_V
  where TREEID = STPD2.TREEID)
),

uTree as (
  select distinct STPDV.TREEID as "TREEID", case STPDV.ACTIVITY_TYPE_ID
       when 1 then 'TreePlanting'
       when 2 then 'Stumping'
       when 3 then 'TransPlanting' 
       end as "ACT_TYPE"
       from STP_DEFICIENCY_V STPDV
       where STPDV.ACTIVITY_TYPE_ID is not null
       order by TREEID asc
),

contracts as (
    select distinct to_number(STPDV.CONTRACTITEM) as "CONTRACT",
    STPDV.CONTRACTYEAR as "YEAR",
    STPCI.PROGRAM as "PROGRAM"
    from STP_DEFICIENCY_V STPDV
    left join STP_CONTRACT_ITEM STPCI on to_number(STPDV.CONTRACTITEM) = STPCI.ITEM_NUM and STPDV.CONTRACTYEAR = STPCI.YEAR
    where STPDV.CONTRACTYEAR = :P0_YEAR
)

select null as "filename",
cursor(
  select
  SYSDATE as "DAT",
  :P0_YEAR as "YR",
  :P0_CONTRACTNUMBER as "CONNUM",
  cursor(
    select distinct cp.PROGRAM as "PROGRAM", :P86_PRINT as "PAY_CERT",
    cursor(
          select 
          cursor(
             select distinct :P0_YEAR ||' -'|| to_char(cc.CONTRACT, '000') as "CONTRACTITEMDISP",
                cursor(
                 select distinct 
                 replace(STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES, '''', '')  as "ITEM",
                 count(STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES) as "QTY",
                 nvl(stpp.unit_price, 0) as "UP",
                 count(STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES) * nvl(stpp.unit_price, 0) as "TOTAL"
                 from STP_DEFICIENCY_V STPDV 
                 join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
                 left join STP_PRICE stpp on STPDV.STOCK_TYPE_ID = stpp.STOCK_TYPE_ID and STPDV.PLANT_TYPE_ID = stpp.PLANT_TYPE_ID and TTREE.SPECIESID = stpp.SPECIES_ID
                 left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
                 where STPDV.CONTRACTYEAR = :P0_YEAR and 
                 to_number(STPDV.CONTRACTITEM) = cc.CONTRACT and 
                 STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
                     (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1
                 group by STPDV.STOCK_TYPE, STPDV.PLANT_TYPE, TTREE.SPECIES, stpp.unit_price
                 
              ) as "PAYMENTDETAILS",
              
              (select distinct
                   sum(count(STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES)) as "QTY"
                   from STP_DEFICIENCY_V STPDV 
                   join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
                   left join STP_PRICE stpp on STPDV.STOCK_TYPE_ID = stpp.STOCK_TYPE_ID and STPDV.PLANT_TYPE_ID = stpp.PLANT_TYPE_ID and TTREE.SPECIESID = stpp.SPECIES_ID
                   left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
                   where STPDV.CONTRACTYEAR = :P0_YEAR and to_number(STPDV.CONTRACTITEM) = c.CONTRACT and 
                   STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
                     (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1
                   group by STPDV.STOCK_TYPE, STPDV.PLANT_TYPE, TTREE.SPECIES, stpp.unit_price
              ) as "TOTAL2"
              
              from contracts c 
              where c.YEAR = :P0_YEAR and c.CONTRACT = cc.CONTRACT and c.PROGRAM = cc.PROGRAM
        ) as "CONTRACTITEM"
        
        from contracts cc
        where exists (select distinct 
                 STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES as "ITEM"
                 from STP_DEFICIENCY_V STPDV 
                 join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
                 left join STP_PRICE stpp on STPDV.STOCK_TYPE_ID = stpp.STOCK_TYPE_ID and STPDV.PLANT_TYPE_ID = stpp.PLANT_TYPE_ID and TTREE.SPECIESID = stpp.SPECIES_ID
                 left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
                 where STPDV.CONTRACTYEAR = :P0_YEAR and to_number(STPDV.CONTRACTITEM) = cc.CONTRACT and 
                 STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
                     (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1 and cc.PROGRAM = cp.PROGRAM
                 group by STPDV.STOCK_TYPE, STPDV.PLANT_TYPE, TTREE.SPECIES, stpp.unit_price
                 ) 
        order by cc.CONTRACT asc
    ) "CONTRACTITEMS"
    from contracts cp
    where exists (select distinct 
                 STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES as "ITEM"
                 from STP_DEFICIENCY_V STPDV 
                 join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
                 left join STP_PRICE stpp on STPDV.STOCK_TYPE_ID = stpp.STOCK_TYPE_ID and STPDV.PLANT_TYPE_ID = stpp.PLANT_TYPE_ID and TTREE.SPECIESID = stpp.SPECIES_ID
                 left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
                 where STPDV.CONTRACTYEAR = :P0_YEAR and to_number(STPDV.CONTRACTITEM) = cp.CONTRACT  and 
                 STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
                     (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1 
                 group by STPDV.STOCK_TYPE, STPDV.PLANT_TYPE, TTREE.SPECIES, stpp.unit_price
                 ) and cp.PROGRAM is not null --and cp.PROGRAM = top.PROGRAM
    group by cp.program  
  ) "PROGRAMS",
  
  cursor(  
    select STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES as "NAME",
    count(STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES) as "GT"
    from STP_DEFICIENCY_V STPDV 
    join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
    left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
    where STPDV.CONTRACTYEAR = :P0_YEAR and
    (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1
    group by STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES
  ) "SUMMARY", -- have to write as subquery due to oracle bug 
  (select sum(tot.GT) from (
    select STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES as "NAME",
    count(STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES) as "GT"
    from STP_DEFICIENCY_V STPDV 
    join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
    left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
    where STPDV.CONTRACTYEAR = :P0_YEAR and
    (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1
    group by STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES
  ) tot) as "GRAND" --again, have to write as subquery due to oracle bug
  
  from contracts top
  where top.program is not null and exists(select distinct 
                 STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES as "ITEM"
                 from STP_DEFICIENCY_V STPDV 
                 join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
                 left join STP_PRICE stpp on STPDV.STOCK_TYPE_ID = stpp.STOCK_TYPE_ID and STPDV.PLANT_TYPE_ID = stpp.PLANT_TYPE_ID and TTREE.SPECIESID = stpp.SPECIES_ID
                 left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
                 where STPDV.CONTRACTYEAR = :P0_YEAR and to_number(STPDV.CONTRACTITEM) = top.CONTRACT  and 
                 STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
                     (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1 
                 group by STPDV.STOCK_TYPE, STPDV.PLANT_TYPE, TTREE.SPECIES, stpp.unit_price
  )
  group by :P0_YEAR
) "data"
from dual
      ]';
      
      return l_return;
    end;
    
    -- won't comment for now, moving to aop_factory eventually
    function AOP_deficiency_list_report(p_snap in number) return varchar2
    as
      l_return clob;
    begin
      if p_snap = 0 then
        l_return := q'[
          with def as(       
       select distinct 
              s.TREEID as "TID",
              s.TAGNUMBER as "TNO",
              s.STOCK_TYPE ||' - '|| s.PLANT_TYPE ||' - '|| t.SPECIES as "ITEM",
              t.CURRENTHEALTH as "HEL",
              t.ROADSIDE as "RD",
              :P0_YEAR ||' -'|| to_char(s.CONTRACTITEM, '000') as "CON",
              t.MUNICIPALITY as "MUN",
              s.DEFICIENCY as "DEF"          
       from (
        select * from
        STP_DEFICIENCY_V 
       )  
       UNPIVOT include nulls(
        MATCH
        for DEFICIENCY
        IN (CROWNDIEBACK, CROWNINSECTDISEASE, EPICORMICBRANCHING, BRANCHINGSTRUCTURE,
        ROOTBALLSIZE, ROOTBALLLOOSE, GIRDLINGROOTS, STEMINSECTDISEASE, STEMTISSUENECROSIS,
        STEMSCARS, GIRDLEDSTEM, PLANTINGHOLESIZE, BACKFILL, PLANTINGLOW, PLANTINGHIGH,
        SOILRETENTIONRING, BURLAPWIREROPE, BEDPREPARATIONDIAMETER, BEDPREPARATIONSOD,
        BEDPREPARATIONCULTIVATION, BEDPREPARATIONCULTIVATIONDEPTH, MULCHDEPTH, MULCHDIAMETER,
        MULCHRING, MULCHSTEM, STEMCROWNROPE, TREEGATORBAG, TREEGUARD, PRUNING, STAKING, 
        EXTRATREE, INCORRECTLOCATION, UNAPPROVEDSPECIES, INCORRECTSIZE, MISSINGTREE)
       ) s
       join STP_TREE_LOCATION_V t on s.TREEID = t.TREEID
       where MATCH = 1
       and s.OBJECTID = (select max(OBJECTID) from STP_DEFICIENCY_V
       where TREEID = s.TREEID)
       and s.CONTRACTOPERATION = 1 and s.activity_type_id<>2
       and s.CONTRACTYEAR = :P0_YEAR
       and t.STATUS = 'Active'
       order by s.TREEID
),

items as(
  select d.TID as "TID",
       d.TNO as "TNO",
       d.ITEM as "ITEM",
       d.HEL as "HEL",
       d.RD as "RD",
       d.CON as "CON",
       MUN as "MUN",
case d.DEF 
when 'CROWNDIEBACK' then 'Crown dieback (<75% crown density)'
when 'CROWNINSECTDISEASE' then 'Crown disease/insect'
when 'EPICORMICBRANCHING' then 'Epicormic branching'
when 'BRANCHINGSTRUCTURE' then 'Poor branching structure'
when 'ROOTBALLSIZE' then 'Root ball size too small'
when 'ROOTBALLLOOSE' then 'Stem loose in root ball'
when 'GIRDLINGROOTS' then 'Root ball and/or roots damage'
when 'STEMINSECTDISEASE' then 'Stem insect/disease'
when 'STEMTISSUENECROSIS' then 'Stem tissue necrosis'
when 'STEMSCARS' then 'Stem scars'
when 'GIRDLEDSTEM' then 'Girdled stem'
when 'PLANTINGHOLESIZE' then 'Planting hole incorrect size'
when 'BACKFILL' then 'Insufficient soil tamping / air pockets present'
when 'PLANTINGLOW' then 'Root ball planted too deep'
when 'PLANTINGHIGH' then 'Root ball planted too high'
when 'SOILRETENTIONRING' then 'Deficient soil water retention ring'
when 'BURLAPWIREROPE' then 'Exposed burlap, wire or rope not removed'
when 'BEDPREPARATIONDIAMETER' then 'Deficient diameter of bed preparation area'
when 'BEDPREPARATIONSOD' then 'Sod remains on site/within bed preparation area'
when 'BEDPREPARATIONCULTIVATION' then 'Deficient soil cultivation'
when 'BEDPREPARATIONCULTIVATIONDEPTH' then 'Deficient soil cultivation depth'
when 'MULCHDEPTH' then 'Deficient depth of mulch'
when 'MULCHDIAMETER' then 'Deficient mulch diameter'
when 'MULCHRING' then 'Deficient mulch retention ring'
when 'MULCHSTEM' then 'Mulch too close to the stem'
when 'STEMCROWNROPE' then 'Stem/crown rope and/or ties present'
when 'TREEGATORBAG' then 'Missing gator bag'
when 'TREEGUARD' then 'Missing tree guard'
when 'PRUNING' then 'Crown requires pruning'
when 'STAKING' then 'Staking required'
when 'EXTRATREE' then 'Extra tree not required'
when 'INCORRECTLOCATION' then 'Transplant Tree to Correct Location'
when 'UNAPPROVEDSPECIES' then 'Unapproved Species Substitution'
when 'INCORRECTSIZE' then 'Incorrect Tree Size'
when 'MISSINGTREE' then 'Missing Tree'
end as "DEF",
case d.DEF
when 'CROWNDIEBACK' then 'Replace Tree'
when 'CROWNINSECTDISEASE' then 'Replace Tree'
when 'EPICORMICBRANCHING' then 'Replace Tree'
when 'BRANCHINGSTRUCTURE' then 'Replace Tree'
when 'ROOTBALLSIZE' then 'Replace Tree'
when 'ROOTBALLLOOSE' then 'Replace Tree'
when 'GIRDLINGROOTS' then 'Replace Tree'
when 'STEMINSECTDISEASE' then 'Replace Tree'
when 'STEMTISSUENECROSIS' then 'Replace Tree'
when 'STEMSCARS' then 'Replace Tree'
when 'GIRDLEDSTEM' then 'Replace Tree'
when 'PLANTINGHOLESIZE' then 'Increase diameter of planting hole'
when 'BACKFILL' then 'Tamp backfill to eliminate air pockets'
when 'PLANTINGLOW' then 'Raise tree so root collar 5 - 10 cm above grade'
when 'PLANTINGHIGH' then 'Lower tree so root collar 5 - 10 cm above grade'
when 'SOILRETENTIONRING' then 'Add/correct soil water retention ring'
when 'BURLAPWIREROPE' then 'Remove burlap, wire and/or rope'
when 'BEDPREPARATIONDIAMETER' then 'Increase diameter of bed preparation area'
when 'BEDPREPARATIONSOD' then 'Remove sod from bed preparation area'
when 'BEDPREPARATIONCULTIVATION' then 'Cultivate bed preparation area'
when 'BEDPREPARATIONCULTIVATIONDEPTH' then 'Increase depth of cultivation'
when 'MULCHDEPTH' then 'Increase depth of mulch'
when 'MULCHDIAMETER' then 'Increase diameter of mulch'
when 'MULCHRING' then 'Add/correct mulch water retention ring'
when 'MULCHSTEM' then 'Move mulch a minimum of 5 cm away from stem'
when 'STEMCROWNROPE' then 'Remove rope and/or ties from tree crown'
when 'TREEGATORBAG' then 'Install TreeGator bag'
when 'TREEGUARD' then 'Install tree guard'
when 'PRUNING' then 'Prune crown to remove dead, diseased or broken branches'
when 'STAKING' then 'Stake leaning or loose tree, correct inproper staking'
when 'EXTRATREE' then 'Remove Extra Tree and Restore Site'
when 'INCORRECTLOCATION' then 'Transplant Tree to Correct Location'
when 'UNAPPROVEDSPECIES' then 'Replace Tree'
when 'INCORRECTSIZE' then 'Replace Tree'
when 'MISSINGTREE' then 'Replace Tree'
end as "REP"
from DEF d
)

select null as "filename",
cursor(
  select 
  SYSDATE as "DAT",
  :P0_YEAR as "YR",
  :P0_CONTRACTNUMBER as "CONNUM",
  cursor( 
    select ii.MUN as "MUN", 
    ii.CON as "CON", 
    ii.RD as "RD",
    cursor(
       select distinct i.TID as "TID",
       i.TNO as "TNO",
       i.ITEM as "ITEM",
       i.HEL as "HEL",
       i.DEF as "DEF", 
       i.REP as "REP"
       from items i
       where convert(i.MUN, 'AL16UTF16', 'AL32UTF8') = ii.MUN
       and i.CON = ii.CON
       and convert(i.RD, 'AL16UTF16', 'AL32UTF8') = ii.RD
    ) "ITEMS"
    from items ii 
    where exists(
      select distinct i.TID as "TID",
       i.TNO as "TNO",
       i.ITEM as "ITEM",
       i.HEL as "HEL",
       i.DEF as "DEF", 
       i.REP as "REP"
       from items i
       where i.MUN = ii.MUN
       and i.CON = ii.CON
       and i.RD = ii.RD
    )
    group by ii.MUN, ii.CON, ii.RD
    order by ii.MUN, ii.CON, ii.RD
  ) "OUTER"
  from dual
  group by :P0_YEAR
) "data"
from dual   
        ]';
        
        else
        l_return := q'[
          select null as "filename",
cursor(
  select 
  SYSDATE as "DAT",
  :P0_YEAR as "YR",
  :P0_CONTRACTNUMBER as "CONNUM",
  cursor( 
    select s.MUNICIPALITY as "MUN", 
    :P0_YEAR ||' - '|| to_char(s.CONTRACTITEM, '000') as "CON", 
    s.ROADSIDE as "RD",
    cursor(
       select distinct ss.TREEID as "TID",
       ss.TAGNUMBER as "TNO",
       ss.ITEM as "ITEM",
       ss.HEALTH as "HEL",
       ss.DEF as "DEF", 
       ss.REP as "REP"
       from STP_DEFICIENCY_LIST_SNAPSHOTS ss 
       where s.CURRENTYEAR = :P0_YEAR 
       and ss.MUNICIPALITY= s.MUNICIPALITY
       and ss.CONTRACTITEM = s.CONTRACTITEM
       and ss.ROADSIDE = s.ROADSIDE
       order by ss.TREEID asc
    ) "ITEMS"
    from STP_DEFICIENCY_LIST_SNAPSHOTS s 
    where exists(
      select distinct ss.TREEID as "TID",
       ss.TAGNUMBER as "TNO",
       ss.ITEM as "ITEM",
       ss.HEALTH as "HEL",
       ss.DEF as "DEF", 
       ss.REP as "REP"
       from STP_DEFICIENCY_LIST_SNAPSHOTS ss 
       where s.CURRENTYEAR = :P0_YEAR
       and ss.MUNICIPALITY = s.MUNICIPALITY
       and ss.CONTRACTITEM = s.CONTRACTITEM
       and ss.ROADSIDE = s.ROADSIDE)
       and s.SEQ_ID = ]' || p_snap || q'[
     group by s.MUNICIPALITY, s.CONTRACTITEM, s.ROADSIDE, s.CURRENTYEAR
    order by 1,2,3
  ) "OUTER"
  from dual
  group by :P0_YEAR
) "data"
from dual 
        ]';
        -- TODO: select * from stp_deficiency_list_snapshots where seq_id = p_snap 
      end if;
      
      return l_return;
    end;

end stp_payment_pkg;
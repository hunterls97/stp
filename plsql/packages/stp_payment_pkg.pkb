<<<<<<< HEAD
create or replace package body                                                                                                                                                             stp_payment_pkg as
=======
create or replace package body                                                                                                                                     stp_payment_pkg as
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
    
    --finds every field that was checked by the user and inserts/ updates the STP_PAYMENT_ITEMS table accordingly
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
        

        --apex_debug.log_dbms_output; 
        
        --exception when NO_DATA_FOUND then
           -- l_exist := '--';
    end;
    
    --When the pay button is pressed, sets all the items to paid where they were previously set to assign for payment
    procedure process_payment
    as
      
    begin
      update bsmart_data.STP_PAYMENT_ITEMS
      set PAYMENT_STATUS = 2,
      PAYMENT_CERT_NO = (select max(nvl(PAYMENT_CERT_NO,0)) + 1 from bsmart_data.STP_PAYMENT_ITEMS)
      where PAYMENT_STATUS = 1;
    end;
    
<<<<<<< HEAD
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
        STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES,
        TTREE.CURRENTTREEHEALTH,
        d.DEF,
        d.REP,
        to_number(STPDV.CONTRACTITEM),
        TTREE.MUNICIPALITY,
        TTREE.SIDEOFSTREET
     from STP_DEFICIENCY_V STPDV
     join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
     join (
      select 
       STPDV.TREEID as "TREEID",
       case
       when STPDV.CROWNDIEBACK = 1 then 'Crown dieback (<75% crown density)'
       when STPDV.CROWNINSECTDISEASE = 1 then 'Crown disease/insect'
       when STPDV.EPICORMICBRANCHING = 1 then 'Epicormic branching'
       when STPDV.BRANCHINGSTRUCTURE = 1 then 'Poor branching structure'
       when STPDV.ROOTBALLSIZE = 1 then 'Root ball size too small'
       when STPDV.ROOTBALLLOOSE = 1 then 'Stem loose in root ball'
       when STPDV.GIRDLINGROOTS = 1 then 'Root ball and/or roots damage'
       when STPDV.STEMINSECTDISEASE = 1 then 'Stem insect/disease'
       when STPDV.STEMTISSUENECROSIS = 1 then 'Stem tissue necrosis'
       when STPDV.STEMSCARS = 1 then 'Stem scars'
       when STPDV.GIRDLEDSTEM = 1 then 'Girdled stem'
       -- all above need tree replacement
       when STPDV.PLANTINGHOLESIZE = 1 then 'Planting hole incorrect size'
       when STPDV.BACKFILL = 1 then 'Insufficient soil tamping / air pockets present'
       when STPDV.PLANTINGLOW = 1 then 'Root ball planted too deep'
       when STPDV.PLANTINGHIGH = 1 then 'Root ball planted too high'
       when STPDV.SOILRETENTIONRING = 1 then 'Deficient soil water retention ring'
       when STPDV.BURLAPWIREROPE = 1 then 'Exposed burlap, wire or rope not removed'
       when STPDV.BEDPREPARATIONDIAMETER = 1 then 'Deficient diameter of bed preparation area'
       when STPDV.BEDPREPARATIONSOD = 1 then 'Sod remains on site/within bed preparation area'
       when STPDV.BEDPREPARATIONCULTIVATION = 1 then 'Deficient soil cultivation'
       when STPDV.BEDPREPARATIONCULTIVATIONDEPTH = 1 then 'Deficient soil cultivation depth'
       when STPDV.MULCHDEPTH = 1 then 'Deficient depth of mulch'
       when STPDV.MULCHDIAMETER = 1 then 'Deficient mulch diameter'
       when STPDV.MULCHRING = 1 then 'Deficient mulch retention ring'
       when STPDV.MULCHSTEM = 1 then 'Mulch too close to the stem'
       when STPDV.STEMCROWNROPE = 1 then 'Stem/crown rope and/or ties present'
       when STPDV.TREEGATORBAG = 1 then 'Missing gator bag'
       when STPDV.TREEGUARD = 1 then 'Missing tree guard'
       when STPDV.PRUNING = 1 then 'Crown requires pruning'
       when STPDV.STAKING = 1 then 'Staking required'
       end as "DEF",
    
       case
       when STPDV.CROWNDIEBACK = 1 or
       STPDV.CROWNINSECTDISEASE = 1 or
       STPDV.EPICORMICBRANCHING = 1 or
       STPDV.BRANCHINGSTRUCTURE = 1 or
       STPDV.ROOTBALLSIZE = 1  or
       STPDV.ROOTBALLLOOSE = 1 or
       STPDV.GIRDLINGROOTS = 1 or
       STPDV.STEMINSECTDISEASE = 1 or
       STPDV.STEMTISSUENECROSIS = 1 or
       STPDV.STEMSCARS = 1 or
       STPDV.GIRDLEDSTEM = 1 then 'Replace Tree'
       -- all above need tree replacement
       when STPDV.PLANTINGHOLESIZE = 1 then 'Increase diameter of planting hole'
       when STPDV.BACKFILL = 1 then 'Tamp backfill to eliminate air pockets'
       when STPDV.PLANTINGLOW = 1 then 'Raise tree so root collar 5 - 10 cm above grade'
       when STPDV.PLANTINGHIGH = 1 then 'Lower tree so root collar 5 - 10 cm above grade'
       when STPDV.SOILRETENTIONRING = 1 then 'Add/correct soil water retention ring'
       when STPDV.BURLAPWIREROPE = 1 then 'Remove burlap, wire and/or rope'
       when STPDV.BEDPREPARATIONDIAMETER = 1 then 'Increase diameter of bed preparation area'
       when STPDV.BEDPREPARATIONSOD = 1 then 'Remove sod from bed preparation area'
       when STPDV.BEDPREPARATIONCULTIVATION = 1 then 'Cultivate bed preparation area'
       when STPDV.BEDPREPARATIONCULTIVATIONDEPTH = 1 then 'Increase depth of cultivation'
       when STPDV.MULCHDEPTH = 1 then 'Increase depth of mulch'
       when STPDV.MULCHDIAMETER = 1 then 'Increase diameter of mulch'
       when STPDV.MULCHRING = 1 then 'Add/correct mulch water retention ring'
       when STPDV.MULCHSTEM = 1 then 'Move mulch a minimum of 5 cm away from stem'
       when STPDV.STEMCROWNROPE = 1 then 'Remove rope and/or ties from tree crown'
       when STPDV.TREEGATORBAG = 1 then 'Install TreeGator bag'
       when STPDV.TREEGUARD = 1 then 'Install tree guard'
       when STPDV.PRUNING = 1 then 'Prune crown to remove dead, diseased or broken branches'
       when STPDV.STAKING = 1 then 'Stake leaning or loose tree, correct inproper staking'
       end as "REP"
       from STP_DEFICIENCY_V STPDV
     ) d on STPDV.TREEID = d.TREEID
     where STPDV.CONTRACTYEAR = p_year 
     and d.DEF is not null; 
    end;
    
=======
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
    function AOP_payment_report return varchar2
    as
    l_return clob;
    begin
      l_return := q'[
<<<<<<< HEAD
                  with status as (
=======
                with status as (
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
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
<<<<<<< HEAD
)/*,

totals as (
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
)*/
=======
)
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016

select null as "filename",
cursor(
  select distinct cursor(
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
<<<<<<< HEAD
                 where STPDV.CONTRACTYEAR = :P0_YEAR and 
                 to_number(STPDV.CONTRACTITEM) = cc.CONTRACT and 
                 STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
=======
                 where STPDV.CONTRACTYEAR = :P0_YEAR and to_number(STPDV.CONTRACTITEM) = cc.CONTRACT and 
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
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
<<<<<<< HEAD
                   STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
=======
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
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
<<<<<<< HEAD
                 STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
=======
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
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
<<<<<<< HEAD
                 STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
=======
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
                     (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1 
                 group by STPDV.STOCK_TYPE, STPDV.PLANT_TYPE, TTREE.SPECIES, stpp.unit_price
                 ) and cp.PROGRAM is not null --and cp.PROGRAM = top.PROGRAM
    group by cp.program  
<<<<<<< HEAD
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
  
=======
  ) "PROGRAMS"
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
  from contracts top
  where top.program is not null and exists(select distinct 
                 STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES as "ITEM"
                 from STP_DEFICIENCY_V STPDV 
                 join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
                 left join STP_PRICE stpp on STPDV.STOCK_TYPE_ID = stpp.STOCK_TYPE_ID and STPDV.PLANT_TYPE_ID = stpp.PLANT_TYPE_ID and TTREE.SPECIESID = stpp.SPECIES_ID
                 left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
                 where STPDV.CONTRACTYEAR = :P0_YEAR and to_number(STPDV.CONTRACTITEM) = top.CONTRACT  and 
<<<<<<< HEAD
                 STPDV.CREATEDATE in (select max(s2.CREATEDATE) from STP_DEFICIENCY_V s2 where s2.TREEID = STPDV.TREEID) and
=======
>>>>>>> b1dc7e93e85fa59b54410bfe3248bd78aed66016
                     (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1 
                 group by STPDV.STOCK_TYPE, STPDV.PLANT_TYPE, TTREE.SPECIES, stpp.unit_price
  )
  group by top.program
) "data"
from dual
      ]';
      
      return l_return;
    end;

end stp_payment_pkg;
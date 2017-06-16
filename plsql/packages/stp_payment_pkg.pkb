create or replace package body                                                                                                                                     stp_payment_pkg as
    
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
                 where STPDV.CONTRACTYEAR = :P0_YEAR and to_number(STPDV.CONTRACTITEM) = cc.CONTRACT and 
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
                     (case when (:P86_PRINT = 'c' and STPPI.PAYMENT_STATUS = 1 ) then 1
                     when (:P86_PRINT<>'c' and STPPI.PAYMENT_CERT_NO = to_number(:P86_PRINT)) then 1
                     else 0 end) = 1 
                 group by STPDV.STOCK_TYPE, STPDV.PLANT_TYPE, TTREE.SPECIES, stpp.unit_price
                 ) and cp.PROGRAM is not null --and cp.PROGRAM = top.PROGRAM
    group by cp.program  
  ) "PROGRAMS"
  from contracts top
  where top.program is not null and exists(select distinct 
                 STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES as "ITEM"
                 from STP_DEFICIENCY_V STPDV 
                 join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
                 left join STP_PRICE stpp on STPDV.STOCK_TYPE_ID = stpp.STOCK_TYPE_ID and STPDV.PLANT_TYPE_ID = stpp.PLANT_TYPE_ID and TTREE.SPECIESID = stpp.SPECIES_ID
                 left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
                 where STPDV.CONTRACTYEAR = :P0_YEAR and to_number(STPDV.CONTRACTITEM) = top.CONTRACT  and 
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
create or replace package body             stp_payment_pkg as
    
    --finds every field that was checked by the user and inserts/ updates the STP_PAYMENT_ITEMS table accordingly
    procedure process_checked_fields
    as
      l_exist varchar2(32000);
    begin 
        sys.dbms_output.enable;
        for i in 1..APEX_APPLICATION.G_F01.COUNT loop
            
            select TREEID into l_exist from bsmart_data.STP_PAYMENT_ITEMS where TREEID = APEX_APPLICATION.G_F01(i); 
            sys.dbms_output.put_line(l_exist); 
            
            merge into STP_PAYMENT_ITEMS STPPI
            using STP_DEFICIENCY_V STPDV
            on STPPI.TREEID = STPDV.TREEID
            when matched then 
            update set PAYMENT_STATUS = 0 where TREEID = APEX_APPLICATION.G_F01(i);
            when not matched then
            insert into STP_PAYMENT_ITEMS(TREEID, ACTIVITY_TYPE)
            values(STPDV.TREEID, STPDV.ACTIVITY_TYPE_ID)
            
            /*select distinct TREEID, ACTIVITY_TYPE_ID from STP_DEFICIENCY_V
            where TREEID = APEX_APPLICATION.G_F01(i); 
            
            /*case when APEX_APPLICATION.G_F01(i) = l_exist then
            update STP_PAYMENT_ITEMS set PAYMENT_STATUS = 0 where TREEID = APEX_APPLICATION.G_F01(i);
            else
            insert into STP_PAYMENT_ITEMS(TREEID, ACTIVITY_TYPE)
            select distinct TREEID, ACTIVITY_TYPE_ID from STP_DEFICIENCY_V
            where TREEID = APEX_APPLICATION.G_F01(i); 
            
            end case;*/
        end loop;
        

        apex_debug.log_dbms_output; 
    end;

    procedure process_payment
    as
      
    begin
      update bsmart_data.STP_PAYMENT_ITEMS
      set PAYMENT_STATUS = 2
      where PAYMENT_STATUS = 1;
    end;

end stp_payment_pkg;
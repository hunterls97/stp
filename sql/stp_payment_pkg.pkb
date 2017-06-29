create or replace package body                                                                                                 stp_payment_pkg as
    
    --finds every field that was checked by the user and inserts/ updates the STP_PAYMENT_ITEMS table accordingly
    procedure process_checked_fields
    as
      l_exist varchar2(32000);
      l_temp1 number;
      l_temp2 number;
    begin 
        sys.dbms_output.enable;
        for i in 1..APEX_APPLICATION.G_F01.COUNT loop
            
            select count(*) into l_temp1 from bsmart_data.STP_PAYMENT_ITEMS where TREEID = APEX_APPLICATION.G_F01(i);
            
            if l_temp1 != 0 then
              select TREEID into l_exist from bsmart_data.STP_PAYMENT_ITEMS where TREEID = APEX_APPLICATION.G_F01(i);
            end if;
            --sys.dbms_output.put_line(l_exist); 
            
            /*merge into STP_PAYMENT_ITEMS STPPI
            using STP_DEFICIENCY_V STPDV
            on (STPPI.TREEID = STPDV.TREEID)
            when matched then 
            update set PAYMENT_STATUS = 0 where TREEID = APEX_APPLICATION.G_F01(i);*/
             
            sys.dbms_output.put_line(l_exist); 
            apex_debug.log_dbms_output; 
            
            case when APEX_APPLICATION.G_F01(i) = l_exist then
                select PAYMENT_STATUS into l_temp2 from bsmart_data.STP_PAYMENT_ITEMS where TREEID = APEX_APPLICATION.G_F01(i);
                
                if l_temp2 = 1 then
                update STP_PAYMENT_ITEMS set PAYMENT_STATUS = 0 where TREEID = APEX_APPLICATION.G_F01(i);
                else
                update STP_PAYMENT_ITEMS set PAYMENT_STATUS = 1 where TREEID = APEX_APPLICATION.G_F01(i);
                end if;
            else
            insert into STP_PAYMENT_ITEMS(TREEID, ACTIVITY_TYPE, PAYMENT_STATUS)
            select distinct TREEID, ACTIVITY_TYPE_ID, 1 from STP_DEFICIENCY_V
            where TREEID = APEX_APPLICATION.G_F01(i);
            end case;
            
        end loop;
        

        apex_debug.log_dbms_output; 
        
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

end stp_payment_pkg;
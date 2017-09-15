create or replace package body                         stp_ew_util_pkg as
procedure create_new_col(
	p_year in number
	) as
	l_query varchar2(8000);
begin

if  apex_collection.collection_exists(P_COLLECTION_NAME=>'COL_EXTRA_WORK')
    then
    APEX_COLLECTION.DELETE_COLLECTION('COL_EXTRA_WORK');
    end if;
    
    l_query :=   q'[select    stp_contract_item.id,                                                 --c001
                  stp_contract_item.contract_item_num,                                            --c002               
                  null as created_by,                                                             --c003
                  null as created_on,                                                             --c004
                  null as updated_by,                                                             --c005
                  null as updated_on,                                                             --c006
                  null as payment_status,                                                         --c007
                  null as payment_cert_no,                                                        --c008
                  detail_and_payment.qty_assigned as qty_assigned,                                   --c009
                  null as qty_to_pay,                                                             --c010
                  null as price,                                                                  --c011
                  stp_contract_item.regional_road,                                                --c012 
                  stp_contract_item.between_road_1,                                               --c013       
                  stp_contract_item.between_road_2,                                               --c014
                  detail_and_payment.type_id,                                                    --c015
                  detail_and_payment.description,                                                --c016
                  0 as qty_commit_to_pay,                                                         --c017
                  detail_and_payment.contract_detail_id  as contract_detail_id,                                   --c018
                  detail_and_payment.qty_assigned - nvl(detail_and_payment.qty_commited_to_pay,0) as qty_remained_unpaid, --c019
                  detail_and_payment.measurement --c020
                  from  stp_contract_item  join
                  --(stp_ew_payment
                  --on stp_ew_payment.contract_item_id = stp_contract_item.id
                  ----    and stp_extra_work_payment_item.payment_cert_no is null
                  ----    and stp_extra_work_payment_item.payment_status != 2
                  --join stp_contract_detail
                  --on stp_contract_detail.contract_item_id = stp_contract_item.id
                  --    and stp_contract_detail.type_id = 6
                  --    and not exists )
                  (
                  select id as contract_detail_id , contract_item_id, qty_assigned, sum(qty_commited_to_pay) as qty_commited_to_pay, type_id, description, measurement
                                        from (select  stp_contract_detail.id,
                                                      stp_contract_detail.contract_item_id,
                                                      stp_contract_detail.quantity as qty_assigned, 
                                                      stp_ew_payment.qty_commited_to_pay,
                                                      stp_contract_detail.type_id,
                                                      stp_contract_detail.description,
                                                      stp_contract_detail.measurement
                                              from stp_contract_detail 
                                              left join stp_ew_payment 
                                              on stp_contract_detail.id = stp_ew_payment.contract_detail_id)
                                        group by id,
                                                qty_assigned,
                                                type_id,
                                                contract_item_id,
                                                description,
                                                measurement
                  ) detail_and_payment
                  on stp_contract_item.id = detail_and_payment.contract_item_id and stp_contract_item.year = ]' || p_year ||q'[
                   and detail_and_payment.type_id = 6
                      and not exists 
                        (select * from (select id as contract_detail_id
                                        from (select  stp_contract_detail.id,
                                                      stp_contract_detail.contract_item_id,
                                                      stp_ew_payment.qty_assigned, 
                                                      stp_ew_payment.qty_commited_to_pay
                                              from stp_contract_detail 
                                              join stp_ew_payment 
                                              on stp_contract_detail.id = stp_ew_payment.contract_detail_id)
                                        group by id,
                                                qty_assigned
                                        having qty_assigned - sum(qty_commited_to_pay) <= 0
                                        ) a 
                                  where detail_and_payment.contract_detail_id = a.contract_detail_id)
                      order by 1
]';
    
    APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY('COL_EXTRA_WORK', l_query);

end; --end begin               

                
procedure create_col_from_save(
	p_year in number
	) as
	l_query varchar2(8000);
begin

if  apex_collection.collection_exists(P_COLLECTION_NAME=>'COL_EXTRA_WORK')
    then
    APEX_COLLECTION.DELETE_COLLECTION('COL_EXTRA_WORK');
    end if;
stp_ew_util_pkg.update_new_add_rec(p_year);                      
l_query := q'[select    		  
		  stp_ew_payment_save.CONTRACT_ITEM_ID,                                                 --c001
          stp_ew_payment_save.contract_item_num,                                            	--c002               
          stp_ew_payment_save.created_by,                                                       --c003
          stp_ew_payment_save.created_on,                                                       --c004
          stp_ew_payment_save.updated_by,                                                       --c005
          stp_ew_payment_save.updated_on,                                                       --c006
          stp_ew_payment_save.payment_status,                                                   --c007
          stp_ew_payment_save.payment_cert_no,                                                  --c008
          stp_ew_payment_save.qty_assigned,                                   					--c009
          stp_ew_payment_save.qty_to_pay,                                                       --c010
          stp_ew_payment_save.price,                                                            --c011
          stp_ew_payment_save.regional_road,                                                	--c012 
          stp_ew_payment_save.between_road_1,                                               	--c013       
          stp_ew_payment_save.between_road_2,                                               	--c014
          stp_ew_payment_save.type_id,                                                    		--c015
          stp_ew_payment_save.description,                                                		--c016
          stp_ew_payment_save.QTY_COMMITED_TO_PAY,                                              --c017
          stp_ew_payment_save.contract_detail_id,                                   			--c018
          stp_ew_payment_save.qty_remained_unpaid, 									                      --c019	
          stp_ew_payment_save.measurement --c020
from  stp_ew_payment_save join stp_contract_item on stp_ew_payment_save.CONTRACT_ITEM_ID  = stp_contract_item.id and stp_contract_item.year =]' || p_year ||q'[ order by stp_ew_payment_save.CONTRACT_ITEM_ID]';
--l_query := replace(l_query, '{RATE}', to_char(p_rate));
APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY('COL_EXTRA_WORK', l_query);
                      
end; --end begin
                      
procedure update_extra_work_detail as
    begin
                -- APEX_DEBUG.ENABLE (p_level => 2);
                -- APEX_DEBUG.LOG_MESSAGE(
                -- p_message => 'debug begin',
                -- p_level => 2 );
    --loop over input text qty_to_pay seq_id
    for i in 1..apex_application.g_f06.count
        loop
                -- APEX_DEBUG.LOG_MESSAGE(
                -- p_message => 'loop gf begin',
                -- p_level => 2 );
            for c in (select * from apex_collections where collection_name = 'COL_EXTRA_WORK')
            loop
                -- APEX_DEBUG.LOG_MESSAGE(
                -- p_message => 'loop col begin',
                -- p_level => 2 );
                if c.seq_id = apex_application.g_f06(i) and to_number(apex_application.g_f05(i)) is not null then
                    apex_collection.update_member('COL_EXTRA_WORK', c.seq_id,
                        p_c001 => c.c001,
                        p_c002 => c.c002,
                        p_c003 => c.c003,
                        p_c004 => c.c004,
                        p_c005 => c.c005,
                        p_c006 => c.c006,
                        p_c007 => c.c007,
                        p_c008 => c.c008,
                        p_c009 => c.c009,
                        p_c010 => to_number(apex_application.g_f05(i)),
                        p_c011 => c.c011,
                        p_c012 => c.c012,
                        p_c013 => c.c013,
                        p_c014 => c.c014,
                        p_c015 => c.c015,
                        p_c016 => c.c016,
                        p_c017 => c.c017,
                        p_c018 => c.c018,
                        p_c019 => c.c019,
                        p_c020 => c.c020
                        );
                end if;
            end loop;
    end loop;
    --loop over input text price seq_id
    for i in 1..apex_application.g_f08.count
        loop
                -- APEX_DEBUG.LOG_MESSAGE(
                -- p_message => 'loop gf begin',
                -- p_level => 2 );
            for c in (select * from apex_collections where collection_name = 'COL_EXTRA_WORK')
            loop
                -- APEX_DEBUG.LOG_MESSAGE(
                -- p_message => 'loop col begin',
                -- p_level => 2 );
                if c.seq_id = apex_application.g_f08(i) then
                    apex_collection.update_member('COL_EXTRA_WORK', c.seq_id,
                        p_c001 => c.c001,
                        p_c002 => c.c002,
                        p_c003 => c.c003,
                        p_c004 => c.c004,
                        p_c005 => c.c005,
                        p_c006 => c.c006,
                        p_c007 => c.c007,
                        p_c008 => c.c008,
                        p_c009 => c.c009,
                        p_c010 => c.c010,
                        --p_c011 => to_number(apex_application.g_f07(i)),
                        p_c011 => to_number(TRIM(leading '$' from TRIM(LEADING ' ' FROM apex_application.g_f07(i)))),
                        p_c012 => c.c012,
                        p_c013 => c.c013,
                        p_c014 => c.c014,
                        p_c015 => c.c015,
                        p_c016 => c.c016,
                        p_c017 => c.c017,
                        p_c018 => c.c018,
                        p_c019 => c.c019,
                        p_c020 => c.c020
                        );
                end if;
            end loop;
    end loop;
    --loop checkbox to update qty commit to pay
    for i in 1..apex_application.g_f03.count
        loop
                -- APEX_DEBUG.LOG_MESSAGE(
                -- p_message => 'loop gf begin',
                -- p_level => 2 );
            for c in (select * from apex_collections where collection_name = 'COL_EXTRA_WORK')
            loop
                -- APEX_DEBUG.LOG_MESSAGE(
                -- p_message => 'loop col begin',
                -- p_level => 2 );    
                --loop over seq_id hidden with checkbox
                if c.seq_id = apex_application.g_f04(i) then
                    apex_collection.update_member('COL_EXTRA_WORK', c.seq_id,
                        p_c001 => c.c001,
                        p_c002 => c.c002,
                        p_c003 => c.c003,
                        p_c004 => c.c004,
                        p_c005 => c.c005,
                        p_c006 => c.c006,
                        p_c007 => c.c007,
                        p_c008 => c.c008,
                        p_c009 => c.c009,
                        p_c010 => c.c010,
                        p_c011 => c.c011,
                        p_c012 => c.c012,
                        p_c013 => c.c013,
                        p_c014 => c.c014,
                        p_c015 => c.c015,
                        p_c016 => c.c016,
                        p_c017 => to_number(c.c010),
                        p_c018 => c.c018,
                        p_c019 => c.c019,
                        p_c020 => c.c020
                        );
                end if;
            end loop;
    end loop;
    end;
    
procedure update_new_add_rec(p_year in number) as
begin
        for new_add_rec in
        
        (select    stp_contract_item.id,                                                 --c001
                  stp_contract_item.contract_item_num,                                            --c002               
                  null as created_by,                                                             --c003
                  null as created_on,                                                             --c004
                  null as updated_by,                                                             --c005
                  null as updated_on,                                                             --c006
                  null as payment_status,                                                         --c007
                  null as payment_cert_no,                                                        --c008
                  detail_and_payment.qty_assigned as qty_assigned,                                   --c009
                  null as qty_to_pay,                                                             --c010
                  null as price,                                                                  --c011
                  stp_contract_item.regional_road,                                                --c012 
                  stp_contract_item.between_road_1,                                               --c013       
                  stp_contract_item.between_road_2,                                               --c014
                  detail_and_payment.type_id,                                                    --c015
                  detail_and_payment.description,                                                --c016
                  0 as qty_commited_to_pay,                                                         --c017
                  detail_and_payment.contract_detail_id  as contract_detail_id,                                   --c018
                  detail_and_payment.qty_assigned - nvl(detail_and_payment.qty_commited_to_pay,0) as qty_remained_unpaid, --c019
                  detail_and_payment.measurement, --c020
                  stp_contract_item.year as CONTRACT_YEAR
                  from  stp_contract_item  join
                  (
                  select id as contract_detail_id , contract_item_id, qty_assigned, sum(qty_commited_to_pay) as qty_commited_to_pay, type_id, description, measurement
                                        from (select  stp_contract_detail.id,
                                                      stp_contract_detail.contract_item_id,
                                                      stp_contract_detail.quantity as qty_assigned, 
                                                      stp_ew_payment.qty_commited_to_pay,
                                                      stp_contract_detail.type_id,
                                                      stp_contract_detail.description,
                                                      stp_contract_detail.measurement
                                              from stp_contract_detail 
                                              left join stp_ew_payment 
                                              on stp_contract_detail.id = stp_ew_payment.contract_detail_id)
                                        group by id,
                                                qty_assigned,
                                                type_id,
                                                contract_item_id,
                                                description,
                                                measurement
                  ) detail_and_payment
                  on stp_contract_item.id = detail_and_payment.contract_item_id and stp_contract_item.year = p_year
                   and detail_and_payment.type_id = 6
                      and not exists 
                        (select * from (select id as contract_detail_id
                                        from (select  stp_contract_detail.id,
                                                      stp_contract_detail.contract_item_id,
                                                      stp_ew_payment.qty_assigned, 
                                                      stp_ew_payment.qty_commited_to_pay
                                              from stp_contract_detail 
                                              join stp_ew_payment 
                                              on stp_contract_detail.id = stp_ew_payment.contract_detail_id)
                                        group by id,
                                                qty_assigned
                                        having qty_assigned - sum(qty_commited_to_pay) <= 0
                                        ) a 
                                  where detail_and_payment.contract_detail_id = a.contract_detail_id)
                      and not exists (select * from stp_ew_payment_save from_last where from_last.contract_detail_id = detail_and_payment.contract_detail_id)
                      order by 1
        )
        loop
          insert into stp_ew_payment_save
          (
          contract_item_id,
          CONTRACT_ITEM_NUM,
          PRICE,
          DESCRIPTION,
          QTY_ASSIGNED,
          QTY_COMMITED_TO_PAY,
          CONTRACT_DETAIL_ID,
          PAYMENT_CERT_NO,
          CREATED_BY,
          CREATED_ON,
          UPDATED_BY,
          UPDATED_ON,
          PAYMENT_STATUS,
          QTY_TO_PAY,
          REGIONAL_ROAD,
          BETWEEN_ROAD_1,
          BETWEEN_ROAD_2,
          TYPE_ID,
          QTY_REMAINED_UNPAID,
          CONTRACT_YEAR,
          MEASUREMENT
          )
          values
          (
          new_add_rec.ID,
          new_add_rec.CONTRACT_ITEM_NUM,
          new_add_rec.PRICE,
          new_add_rec.DESCRIPTION,
          new_add_rec.QTY_ASSIGNED,
          new_add_rec.QTY_COMMITED_TO_PAY,
          new_add_rec.CONTRACT_DETAIL_ID,
          new_add_rec.PAYMENT_CERT_NO,
          new_add_rec.CREATED_BY,
          new_add_rec.CREATED_ON,
          new_add_rec.UPDATED_BY,
          new_add_rec.UPDATED_ON,
          new_add_rec.PAYMENT_STATUS,
          new_add_rec.QTY_TO_PAY,
          new_add_rec.REGIONAL_ROAD,
          new_add_rec.BETWEEN_ROAD_1,
          new_add_rec.BETWEEN_ROAD_2,
          new_add_rec.TYPE_ID,
          new_add_rec.QTY_REMAINED_UNPAID,
          new_add_rec.CONTRACT_YEAR,
          new_add_rec.MEASUREMENT
          );
          end loop;
end;
                      
end; --end pkg
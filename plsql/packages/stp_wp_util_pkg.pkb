create or replace package body                                                                                                                                                                                                                                                                                                                                                                                                             STP_WP_UTIL_PKG as 

procedure create_new_payment_col(
	p_year in number
	) as
	l_query varchar2(8000);
begin

    if  apex_collection.collection_exists(P_COLLECTION_NAME=>'COL_STP_WATERING_PAYMENT')
        then
        APEX_COLLECTION.DELETE_COLLECTION('COL_STP_WATERING_PAYMENT');
        end if;

    l_query := q'[select * from
(select watering_assignment_num, --c001
        rin,                 --c002
        MUNICIPALITY,        --c003
        MAIN_ROAD,           --c004
        BETWEEN_1,           --c005
        BETWEEN_2,           --c006
        ROAD_SIDE,           --c007
        "BROADLEAVED_(GATOR_BAGS)", --c008
        CONIFERS,            --c009
        OTHER_TREES,         --c010
        total_items,         --c011
        YR_AUDIT_WATER_COUNT_CONFIRMED, --c012
        YR_AUDIT_WATER_COUNT_CONFIRMED as qty_to_pay,     --c013
        null as payment_comment, --c014
        watering_assignment_year as watering_assignment_year, --c015
        0 as qty_assigned_to_pay, --c016
        seq_id --c017
    from stp_wa_save
    where FINAL = 1
    and watering_assignment_year = ]'||p_year||q'[order by watering_assignment_num, rin) to_pay

    where not exists 
      (select * from 
          (select * from stp_wa_payment) a 
          where a.rin = to_pay.rin
          and a.road_side = to_pay.ROAD_SIDE
          and a.watering_assignment_num = to_pay.watering_assignment_num
          and a.watering_assignment_year = to_pay.watering_assignment_year)]';

    APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY('COL_STP_WATERING_PAYMENT', l_query);
    end;
    
procedure create_new_payment_col2(
	p_year in number,
  p_wa_num in number
	) as
	l_query varchar2(8000);
  j_query varchar2(8000);
begin
            APEX_DEBUG.ENABLE (p_level => 2);
            APEX_DEBUG.LOG_MESSAGE(
            p_message => 'loop gf3 begin',
            p_level => 2 );
    j_query := q'[delete * from stp_wa_payment_temp where watering_assignment_year =]'||p_year;

    if  apex_collection.collection_exists(P_COLLECTION_NAME=>'COL_STP_WATERING_PAYMENT')
        then
        APEX_COLLECTION.DELETE_COLLECTION('COL_STP_WATERING_PAYMENT');
        end if;

    l_query := q'[select * from
(select watering_assignment_num, --c001
        rin,                 --c002
        MUNICIPALITY,        --c003
        MAIN_ROAD,           --c004
        BETWEEN_1,           --c005
        BETWEEN_2,           --c006
        ROAD_SIDE,           --c007
        "BROADLEAVED_(GATOR_BAGS)", --c008
        CONIFERS,            --c009
        total_items,         --c010
        "WATER_COUNT_(TOTAL_WATERED)", --c011
        YR_AUDIT_WATER_COUNT_CONFIRMED, --c012
        YR_AUDIT_WATER_COUNT_CONFIRMED as qty_to_pay,     --c013
        comments as payment_comment, --c014
        watering_assignment_year as watering_assignment_year, --c015
        0 as qty_assigned_to_pay, --c016
        seq_id, --c017
        0 as is_assigned, --c018 addded aug 21st
        OTHER_TREES       --c019
    from stp_wa_save
    where FINAL = 1
    and watering_assignment_year = ]'||p_year|| q'[ and watering_assignment_num = ]'||p_wa_num||q'[ order by watering_assignment_num, rin) to_pay

    where not exists 
      (select * from 
          (select * from stp_wa_payment) a 
          where a.rin = to_pay.rin
          and a.road_side = to_pay.ROAD_SIDE
          and a.watering_assignment_num = to_pay.watering_assignment_num
          and a.watering_assignment_year = to_pay.watering_assignment_year)]';

    APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY('COL_STP_WATERING_PAYMENT', l_query);
    end;


procedure create_col_from_payment_temp(
	p_year in number
    )as
	l_query varchar2(8000);
    
begin
    if  apex_collection.collection_exists(P_COLLECTION_NAME=>'COL_STP_WATERING_PAYMENT')
        then
        APEX_COLLECTION.DELETE_COLLECTION('COL_STP_WATERING_PAYMENT');
        end if;
        l_query := q'[select  watering_assignment_num, --c001
                rin,                 --c002
                MUNICIPALITY,        --c003
                MAIN_ROAD,           --c004
                BETWEEN_1,           --c005
                BETWEEN_2,           --c006
                ROAD_SIDE,           --c007
                "BROADLEAVED_(GATOR_BAGS)", --c008
                CONIFERS,            --c009
                OTHER_TREES,         --c010
                total_items,         --c011
                YR_AUDIT_WATER_COUNT_CONFIRMED, --c012
                qty_to_pay,          --c013
                payment_comment,     --c014
                watering_assignment_year,    --c015
                qty_assigned_to_pay, --c016
                seq     --c017
        from stp_wa_payment_temp
        where 
        watering_assignment_year = ]'||p_year||
        q'[
        order by watering_assignment_num, rin]';


    APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY('COL_STP_WATERING_PAYMENT', l_query);
    
end;

procedure create_col_from_payment_temp2(
	p_year in number,
  p_wa_num in number
    )as
	l_query varchar2(8000);
    
begin
    if  apex_collection.collection_exists(P_COLLECTION_NAME=>'COL_STP_WATERING_PAYMENT')
        then
        APEX_COLLECTION.DELETE_COLLECTION('COL_STP_WATERING_PAYMENT');
        end if;
    l_query := q'[select  watering_assignment_num, --c001
        rin,                 --c002
        MUNICIPALITY,        --c003
        MAIN_ROAD,           --c004
        BETWEEN_1,           --c005
        BETWEEN_2,           --c006
        ROAD_SIDE,           --c007
        "BROADLEAVED_(GATOR_BAGS)", --c008
        CONIFERS,            --c009
        total_items,         --c010
        "WATER_COUNT_(TOTAL_WATERED)", --c011
        YR_AUDIT_WATER_COUNT_CONFIRMED, --c012
        qty_to_pay as qty_to_pay,     --c013
        comments as payment_comment, --c014
        watering_assignment_year as watering_assignment_year, --c015
        QTY_ASSIGNED_TO_PAY as qty_assigned_to_pay, --c016
        seq, --c017
        null as is_assigned, --c018
        OTHER_TREES         --c019
    from stp_wa_payment_temp
    where
        watering_assignment_year = ]'||p_year||
        q'[and watering_assignment_num = ]'||p_wa_num
        ||q'[
        order by watering_assignment_num, rin]';


    APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY('COL_STP_WATERING_PAYMENT', l_query);
    
end;




procedure update_wp_detail2 as
begin
--cover the case assign -> save -> unassign -> save
    --2 checkbox 7 seqid
--1 qty_to_pay 8 seqid
--3 comments 9 seqid

    --loop checkbox to update assign
      for i in 1..apex_application.g_f02.count

        loop

            for c in (select * from apex_collections where collection_name = 'COL_STP_WATERING_PAYMENT')
            loop
                APEX_DEBUG.LOG_MESSAGE(
                p_message => 'loop col begin',
                p_level => 2 );    
               --loop over seq_id hidden with checkbox
                if c.seq_id = apex_application.g_f02(i) then  
                    apex_collection.update_member('COL_STP_WATERING_PAYMENT', c.seq_id,
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
                        p_c014 => c.c014,  --apex_application.g_f03(i),
                        p_c015 => c.c015,
                        p_c016 => c.c016,
                        p_c017 => c.c017,
                        p_c018 => 1,
                        p_c019 => c.c019
                        );
                  end if;
              end loop; --end looping for collection

      
    end loop; --end looping for f02
    
    --end of updating is_assigned
    
    --begin update c013 c016 qty to pay using is_assigned
        --loop checkbox to update assign
    for i in 1..apex_application.g_f01.count

      loop

        for c in (select * from apex_collections where collection_name = 'COL_STP_WATERING_PAYMENT')
        loop
            APEX_DEBUG.LOG_MESSAGE(
            p_message => 'loop col begin',
            p_level => 2 );    
           --loop over seq_id hidden with checkbox
            if c.c018 = 1 then  
                apex_collection.update_member('COL_STP_WATERING_PAYMENT', c.seq_id,
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
                    p_c013 => apex_application.g_f01(c.seq_id),
                    p_c014 => c.c014,  --apex_application.g_f03(i),
                    p_c015 => c.c015,
                    p_c016 => apex_application.g_f01(c.seq_id),
                    p_c017 => c.c017,
                    p_c018 => c.c018,
                    p_c019 => c.c019
                    );
              else
                apex_collection.update_member('COL_STP_WATERING_PAYMENT', c.seq_id,
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
                    p_c013 => apex_application.g_f01(c.seq_id),
                    p_c014 => c.c014,  --apex_application.g_f03(i),
                    p_c015 => c.c015,
                    p_c016 => 0,
                    p_c017 => c.c017,
                    p_c018 => c.c018,
                    p_c019 => c.c019
                    );
              end if;
          end loop; --end looping for collection
    end loop;
            
          

end;

procedure update_wp_detail3 as
begin
    --2 checkbox 7 seqid
--1 qty_to_pay 8 seqid
--3 comments 9 seqid

    --loop checkbox to update qty commit to pay

      for i in 1..apex_application.g_f02.count

        loop

            for c in (select * from apex_collections where collection_name = 'COL_STP_WATERING_PAYMENT')
            loop
                APEX_DEBUG.LOG_MESSAGE(
                p_message => 'loop col begin',
                p_level => 2 );    
               --loop over seq_id hidden with checkbox
                if c.seq_id = apex_application.g_f02(i) then  
                    apex_collection.update_member('COL_STP_WATERING_PAYMENT', c.seq_id,
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
                        p_c013 => apex_application.g_f01(c.seq_id),
                        p_c014 => c.c014,  --apex_application.g_f03(i),
                        p_c015 => c.c015,
                        p_c016 => apex_application.g_f01(c.seq_id),
                        p_c017 => c.c017
                        );
                  end if;
              end loop; --end looping for collection

      
    end loop; --end looping for f02

end;

end;
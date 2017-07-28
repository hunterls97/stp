create or replace PACKAGE BODY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     STP_WA_PKG
is

procedure load_watering_item as

l_query varchar(400);

begin
        execute immediate
        'create global temporary table stp_wa_detail_temp
        on commit preserve rows
        as
        select  a.segment_id as rin,
                  a.sideofstreet as road_side,				
                  sdv.contractyear as contract_year,				
                  sdv.contractitem as contract_item,				
                  sdv.contractnumber as contract_item_num,							
                  a.onstreet as on_street,                      
                  a.from_street as from_street, 	
                  a.to_street as to_street,
                  sum(case when sdv.plant_type_id = 4 or sdv.plant_type_id = 5 then 1 else 0 end) b_tree_count,
                  sum(case when sdv.plant_type_id = 1 or sdv.plant_type_id = 2 or sdv.plant_type_id = 3 then 1 else 0 end) c_tree_count,
                  sum(case when sdv.plant_type_id = 7 or sdv.plant_type_id = 8 or sdv.plant_type_id = 9 then 1 else 0 end) p_tree_count,
                  sum(case when sdv.plant_type_id = 6 then 1 else 0 end) s_tree_count,
                  count(a.treeid) as tree_count
                  --null as watering_tree_count, 	
                  --null as watering_assignment_year,
                  --null as watering_assignment_num,
                  --null as location_notes,	
                  --null as rin_on_hold_comments,
                  --null as rin_comments
          from 
            (select fstt.onstreet,
                    fstt.segment_id,
                    fstt.sideofstreet,
                    fstt.yearplanted,
                    fstt.treeid,
                    v_roads.from_street,
                    v_roads.to_street
            from transd.fsttree@etrans fstt
            join v_roads on v_roads.segment_id = fstt.segment_id
            -- where yearplanted = 2013
            ) a -- change to three years
          join stp_deficiency_v sdv on sdv.treeid = a.treeid
          group by    segment_id, 
                sideofstreet, 
                contractyear, 
                contractitem, 
                contractnumber, 
                onstreet, 
                from_street, 
                to_street'
                ;
        commit;
        -- execute immediate '
        -- --insert into stp_wa_detail_temp
        -- insert into stp_wa_detail_temp
        -- select  a.segment_id as rin,
        --               a.sideofstreet as road_side,				
        --               sdv.contractyear as contract_year,				
        --               sdv.contractitem as contract_item,				
        --               sdv.contractnumber as contract_item_num,							
        --               a.onstreet as on_street,                      
        --               a.from_street as from_street, 	
        --               a.to_street as to_street,
        --               sum(case when sdv.plant_type_id = 4 or sdv.plant_type_id = 5 then 1 else 0 end) b_tree_count,
        --               sum(case when sdv.plant_type_id = 1 or sdv.plant_type_id = 2 or sdv.plant_type_id = 3 then 1 else 0 end) c_tree_count,
        --               sum(case when sdv.plant_type_id = 7 or sdv.plant_type_id = 8 or sdv.plant_type_id = 9 then 1 else 0 end) p_tree_count,
        --               sum(case when sdv.plant_type_id = 6 then 1 else 0 end) s_tree_count,
        --               count(a.treeid) as tree_count
        --       from 
        --         (select fstt.onstreet,
        --                 fstt.segment_id,
        --                 fstt.sideofstreet,
        --                 fstt.yearplanted,
        --                 fstt.treeid,
        --                 v_roads.from_street,
        --                 v_roads.to_street
        --         from transd.fsttree@etrans fstt
        --         join v_roads on v_roads.segment_id = fstt.segment_id
        --         where yearplanted = 2013
        --         ) a -- change to three years
        --       join stp_deficiency_v sdv on sdv.treeid = a.treeid
        --       group by    segment_id, 
        --             sideofstreet, 
        --             contractyear, 
        --             contractitem, 
        --             contractnumber, 
        --             onstreet, 
        --             from_street, 
        --             to_street

        -- ';
        -- commit;
        --l_query := q'[delete from table stp_wa_detail where contract_year = ]'||p_year;
        execute immediate 'truncate table  stp_wa_detail';
        commit;

        execute immediate '
            insert into stp_wa_detail
            (rin,
            road_side,
            contract_year,
            contract_item,
            contract_item_num,
            on_street,
            from_street,
            to_street,
            b_tree_count,
            c_tree_count,
            p_tree_count,
            s_tree_count,
            tree_count,
            watering_tree_count,
            watering_assignment_year,
            WATERING_ASSIGNMENT_NUM,
            location_notes,
            rin_on_hold_comments,
            rin_comments
            )
        select 	rin,
                road_side,
                contract_year,
                contract_item,
                contract_item_num,
                on_street,
                from_street,
                to_street,
                b_tree_count,
                c_tree_count,
                p_tree_count,
                s_tree_count,
                tree_count,
                null as watering_tree_count,
                null as watering_assignment_year,
                null as WATERING_ASSIGNMENT_NUM,
                null as location_notes,
                null as rin_on_hold_comments,
                null as rin_comments
        from stp_wa_detail_temp
        ';
        commit;
        
        execute immediate 'truncate table stp_wa_detail_temp';
        execute immediate 'drop table stp_wa_detail_temp';
        execute immediate '
            create global temporary table stp_wa_detail_temp
                on commit preserve rows
                as
           select rin as rin,
                   road_side as road_side,
                   0 as b_tree_count,
                   0 as  c_tree_count,
                   0 as p_tree_count,
                   0 as s_tree_count,
                   1 as is_on_hold,
                   0 as is_assigned_total
             from stp_wa_detail
             group by rin,
                      road_side
             union all
                        select rin as rin,
                               road_side as road_side,
                               sum(b_tree_count) as b_tree_count,
                               sum(c_tree_count) as c_tree_count,
                               sum(p_tree_count) as p_tree_count,
                               sum(s_tree_count) as s_tree_count,
                               0 as is_on_hold,
                               1 as is_assigned_total
                         from stp_wa_detail
                         group by rin,
                                  road_side
            order by  1 asc, 2asc, 7 desc
        ';
        commit;
        execute immediate '
           insert into stp_wa_detail(
                  rin,
                  road_side,
                  b_tree_count,
                  c_tree_count,
                  p_tree_count,
                  s_tree_count,
                  is_on_hold,
                  is_assigned_total
                    )
            select rin,
                  road_side,
                  b_tree_count,
                  c_tree_count,
                  p_tree_count,
                  s_tree_count,
                  is_on_hold,
                  is_assigned_total
            from stp_wa_detail_temp
        ';
        commit;
        
  end;
  
procedure load_watering_item2(p_year in number) as

l_query varchar(5000);
k_query varchar(5000);
j_query varchar(5000);
i_query varchar(5000);
begin
        l_query := 

        q'[create global temporary table stp_wa_detail_tempy
        on commit preserve rows
        as
        select  a.segment_id as rin,
                  a.sideofstreet as road_side,				
                  sdv.contractyear as contract_year,				
                  sdv.contractitem as contract_item,				
                  sdv.contractnumber as contract_item_num,							
                  a.onstreet as on_street,                      
                  a.from_street as from_street, 	
                  a.to_street as to_street,
                  sum(case when sdv.plant_type_id = 4 or sdv.plant_type_id = 5 then 1 else 0 end) b_tree_count,
                  sum(case when sdv.plant_type_id = 1 or sdv.plant_type_id = 2 or sdv.plant_type_id = 3 then 1 else 0 end) c_tree_count,
                  sum(case when sdv.plant_type_id = 7 or sdv.plant_type_id = 8 or sdv.plant_type_id = 9 then 1 else 0 end) p_tree_count,
                  sum(case when sdv.plant_type_id = 6 then 1 else 0 end) s_tree_count,
                  count(a.treeid) as tree_count,
                  a.yearplanted
                  --null as watering_tree_count, 	
                  --null as watering_assignment_year,
                  --null as watering_assignment_num,
                  --null as location_notes,	
                  --null as rin_on_hold_comments,
                  --null as rin_comments
          from 
            (select fstt.onstreet,
                    fstt.segment_id,
                    fstt.sideofstreet,
                    fstt.yearplanted,
                    fstt.treeid,
                    ws_road.from_street,
                    ws_road.to_street
            from transd.fsttree@etrans fstt
            left join ws_road on fstt.segment_id = ws_road.segmentid
            where ((fstt.yearplanted = ]'||p_year||q'[) or  (fstt.yearplanted = ]' ||p_year||q'[-1 ) or (fstt.yearplanted = ]' ||p_year||q'[-2 )) and fstt.status = 'Active'
            ) a -- change to three years
          join stp_deficiency_v sdv on sdv.treeid = a.treeid
          group by    segment_id, 
                sideofstreet, 
                contractyear, 
                contractitem, 
                contractnumber, 
                onstreet, 
                from_street, 
                to_street,
                a.yearplanted]'
                ;
        execute immediate l_query;
        commit;
        
        i_query := q'[delete from stp_wa_detail where temp_save_year =]'||p_year;
        execute immediate i_query;
        commit;

        k_query := q'[
            insert into stp_wa_detail
            (rin,
            road_side,
            contract_year,
            contract_item,
            contract_item_num,
            on_street,
            from_street,
            to_street,
            b_tree_count,
            c_tree_count,
            p_tree_count,
            s_tree_count,
            tree_count,
            watering_tree_count,
            watering_assignment_year,
            WATERING_ASSIGNMENT_NUM,
            location_notes,
            rin_on_hold_comments,
            rin_comments,
            temp_save_year
            )
        select 	rin,
                road_side,
                contract_year,
                contract_item,
                contract_item_num,
                on_street,
                from_street,
                to_street,
                b_tree_count,
                c_tree_count,
                p_tree_count,
                s_tree_count,
                tree_count,
                null as watering_tree_count,
                null as watering_assignment_year,
                null as WATERING_ASSIGNMENT_NUM,
                null as location_notes,
                null as rin_on_hold_comments,
                null as rin_comments,]'||p_year||q'[ as temp_save_year from stp_wa_detail_tempy]';
        execute immediate k_query;
        commit;
        
        execute immediate 'truncate table stp_wa_detail_tempy';
        execute immediate 'drop table stp_wa_detail_tempy';
        execute immediate '
            create global temporary table stp_wa_detail_tempy
                on commit preserve rows
                as
           select rin as rin,
                   road_side as road_side,
                   0 as b_tree_count,
                   0 as  c_tree_count,
                   0 as p_tree_count,
                   0 as s_tree_count,
                   1 as is_on_hold,
                   0 as is_assigned_total
             from stp_wa_detail
             group by rin,
                      road_side
             union all
                        select rin as rin,
                               road_side as road_side,
                               sum(b_tree_count) as b_tree_count,
                               sum(c_tree_count) as c_tree_count,
                               sum(p_tree_count) as p_tree_count,
                               sum(s_tree_count) as s_tree_count,
                               0 as is_on_hold,
                               1 as is_assigned_total
                         from stp_wa_detail
                         group by rin,
                                  road_side
            order by  1 asc, 2asc, 7 desc
        ';
        commit;
        j_query := '[
           insert into stp_wa_detail(
                  rin,
                  road_side,
                  b_tree_count,
                  c_tree_count,
                  p_tree_count,
                  s_tree_count,
                  is_on_hold,
                  is_assigned_total,
                  temp_save_year
                    )
            select rin,
                  road_side,
                  b_tree_count,
                  c_tree_count,
                  p_tree_count,
                  s_tree_count,
                  is_on_hold,
                  is_assigned_total,]'||p_year ||q'[as temp_save_year
            from stp_wa_detail_tempy]';
        execute immediate j_query;
        commit;
        
  end;

procedure load_watering_item3(p_year in number) as

l_query varchar(5000);
k_query varchar(5000);
j_query varchar(5000);
i_query varchar(5000);
begin

    FOR rec IN (SELECT stlv.segment_id    AS rin, 
                       stlv.roadside      AS road_side, 
                       stlv.contractyear  AS contract_year, 
                       stlv.contractitem  AS contract_item,       
                       ws_road.full_name  AS on_street, 
                       ws_road.from_street, 
                       ws_road.to_street, 
                       SUM(CASE 
                             WHEN stlv.plant_type_id = 4 
                                   OR stlv.plant_type_id = 5 THEN 1 
                             ELSE 0 
                           END)           b_tree_count, 
                       SUM(CASE 
                             WHEN stlv.plant_type_id = 1 
                                   OR stlv.plant_type_id = 2 
                                   OR stlv.plant_type_id = 3 THEN 1 
                             ELSE 0 
                           END)           c_tree_count, 
                       SUM(CASE 
                             WHEN stlv.plant_type_id = 7 
                                   OR stlv.plant_type_id = 8 
                                   OR stlv.plant_type_id = 9 THEN 1 
                             ELSE 0 
                           END)           p_tree_count, 
                       SUM(CASE 
                             WHEN stlv.plant_type_id = 6 THEN 1 
                             ELSE 0 
                           END)           s_tree_count, 
                       Count(stlv.treeid) AS tree_count 
                --stlv.yearplanted, 
                FROM   stp_tree_location_v stlv 
                       left join ws_road 
                              ON stlv.segment_id = ws_road.segmentid 
                WHERE  ((stlv.yearplanted = p_year) or  (stlv.yearplanted = p_year-1 ) or (stlv.yearplanted = p_year-2 ))
                
                       AND stlv.status = 'Active' 
                GROUP  BY stlv.segment_id, 
                          stlv.roadside, 
                          stlv.contractyear, 
                          stlv.contractitem,  
                          ws_road.full_name, 
                          ws_road.from_street, 
                          ws_road.to_street) LOOP 
        INSERT INTO stp_wa_detail 
                    (rin, 
                     road_side, 
                     contract_year, 
                     contract_item, 
                     on_street, 
                     from_street, 
                     to_street, 
                     b_tree_count, 
                     c_tree_count, 
                     p_tree_count, 
                     s_tree_count, 
                     tree_count) 
        VALUES      (rec.rin, 
                     rec.road_side, 
                     rec.contract_year, 
                     rec.contract_item, 
                     rec.on_street, 
                     rec.from_street, 
                     rec.to_street, 
                     rec.b_tree_count, 
                     rec.c_tree_count, 
                     rec.p_tree_count, 
                     rec.s_tree_count, 
                     rec.tree_count); 
    END LOOP; 

        i_query := q'[delete from stp_wa_detail where temp_save_year =]'||p_year;
        execute immediate i_query;
        commit;

        k_query := q'[
            insert into stp_wa_detail
            (rin,
            road_side,
            contract_year,
            contract_item,
            contract_item_num,
            on_street,
            from_street,
            to_street,
            b_tree_count,
            c_tree_count,
            p_tree_count,
            s_tree_count,
            tree_count,
            watering_tree_count,
            watering_assignment_year,
            WATERING_ASSIGNMENT_NUM,
            location_notes,
            rin_on_hold_comments,
            rin_comments,
            temp_save_year
            )
        select 	rin,
                road_side,
                contract_year,
                contract_item,
                contract_item_num,
                on_street,
                from_street,
                to_street,
                b_tree_count,
                c_tree_count,
                p_tree_count,
                s_tree_count,
                tree_count,
                null as watering_tree_count,
                null as watering_assignment_year,
                null as WATERING_ASSIGNMENT_NUM,
                null as location_notes,
                null as rin_on_hold_comments,
                null as rin_comments,]'||p_year||q'[ as temp_save_year from stp_wa_detail_tempy]';
        --execute immediate k_query;
        --commit;
        
        --execute immediate 'truncate table stp_wa_detail_tempy';
       -- execute immediate 'drop table stp_wa_detail_tempy';
      /* execute immediate '
            create global temporary table stp_wa_detail_tempy
                on commit preserve rows
                as
           select rin as rin,
                   road_side as road_side,
                   0 as b_tree_count,
                   0 as  c_tree_count,
                   0 as p_tree_count,
                   0 as s_tree_count,
                   1 as is_on_hold,
                   0 as is_assigned_total
             from stp_wa_detail
             group by rin,
                      road_side
             union all
                        select rin as rin,
                               road_side as road_side,
                               sum(b_tree_count) as b_tree_count,
                               sum(c_tree_count) as c_tree_count,
                               sum(p_tree_count) as p_tree_count,
                               sum(s_tree_count) as s_tree_count,
                               0 as is_on_hold,
                               1 as is_assigned_total
                         from stp_wa_detail
                         group by rin,
                                  road_side
            order by  1 asc, 2asc, 7 desc
        '; */
        commit;
        j_query := '[
           insert into stp_wa_detail(
                  rin,
                  road_side,
                  b_tree_count,
                  c_tree_count,
                  p_tree_count,
                  s_tree_count,
                  is_on_hold,
                  is_assigned_total,
                  temp_save_year
                    )
            select rin,
                  road_side,
                  b_tree_count,
                  c_tree_count,
                  p_tree_count,
                  s_tree_count,
                  is_on_hold,
                  is_assigned_total,]'||p_year ||q'[as temp_save_year
            from stp_wa_detail_tempy]';
        --execute immediate j_query;
        commit;
        
  end;



procedure update_upd_ind as
    begin
    update stp_wa_detail
    set upd_ind = 'U'
    where is_on_hold = 1 or is_assigned_total = 1;
    commit;
    
    end;

procedure update_extra_work_detail as
    begin
                -- APEX_DEBUG.ENABLE (p_level => 2);
                -- APEX_DEBUG.LOG_MESSAGE(
                -- p_message => 'debug begin',
                -- p_level => 2 );
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
                        p_c019 => c.c019
                        );
                end if;
            end loop;
    end loop;

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
                        p_c011 => to_number(apex_application.g_f07(i)),
                        p_c012 => c.c012,
                        p_c013 => c.c013,
                        p_c014 => c.c014,
                        p_c015 => c.c015,
                        p_c016 => c.c016,
                        p_c017 => c.c017,
                        p_c018 => c.c018,
                        p_c019 => c.c019
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
                        p_c019 => c.c019                          
                        );
                end if;
            end loop;
    end loop;
    end;
    
    function validate_contractor_upload(p_assign in number, p_year in number) return number
    as
      l_con number;
      l_seq number;
      l_err number := 0;
    begin
      sys.dbms_output.enable;
    
      for i in (
        select ac.SEQ_ID as "SEQ", ac.c001, ac.c002, ac.c003, ac.c004, 
        ac.c005, ac.c006, ac.c007,
        ac.c008, ac.c009, ac.c010,
        ac.c011, ac.c012, ac.c013,
        ac.c014, ac.c015, ac.c018, 
        ac.c019, wa.*
        from STP_WA_SAVE wa
        join apex_collections ac
        on wa.SEQ_ID = ac.c019 --and wa.CONTRACTOR_WATERING_ID = ac.c018
        and wa.WATERING_ASSIGNMENT_NUM = p_assign
        and wa.CONTRACTOR_UPLOAD_VERSION = 0
        and wa.WATERING_ASSIGNMENT_YEAR = p_year
        where ac.collection_name = 'LOAD_CONTENT'
        and ac.c049 in ('INSERT','UPDATE', 'FAILED')
      ) loop     
        l_con := i.c018; -- contractor watering id
        l_seq := i.c019; -- sequence id of assignment ** not seq id of collection
        
        if(to_char(l_con) != to_char(l_seq)) then -- raises error if the sequecne and contractor dont match i.e. contractor changed a field they shouldnt have
        l_err := 1;
          APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE(
            p_collection_name => 'LOAD_CONTENT',
            p_seq => i.SEQ,
            p_attr_number => '20',
            p_attr_value => '_ERR'
          ); 
        end if;
        
        sys.dbms_output.put_line('test ' || i.c002 ||' and ' || i.MUNICIPALITY);
        apex_debug.log_dbms_output;
        
        if(
          to_char(nvl(i.c001, 'null')) != to_char(i.RIN) OR
          to_char(nvl(i.c002, 'null')) != to_char(i.MUNICIPALITY) OR
          to_char(nvl(i.c003, 'null')) != to_char(i.MAIN_ROAD) OR
          to_char(nvl(i.c004, 'null')) != to_char(i.BETWEEN_1) OR
          to_char(nvl(i.c005, 'null')) != to_char(i.BETWEEN_2) OR
          to_char(nvl(i.c006, 'null')) != to_char(i.ROAD_SIDE) OR
          to_char(nvl(i.c018, 'null')) != to_char(i.CONTRACTOR_WATERING_ID) OR
          to_char(nvl(i.c019, 'null')) != to_char(i.SEQ_ID) 
          
          /*nvl(i.c007, 'null') != i."BROADLEAVED_(GATOR_BAGS)" OR
          nvl(i.c008, 'null') !=  OR
          nvl(i.c009, 'null') !=  OR
          nvl(i.c010, 'null') !=  OR
          nvl(i.c011, 'null') !=  OR
          nvl(i.c012, 'null') !=  OR
          nvl(i.c013, 'null') !=  OR
          nvl(i.c014, 'null') !=  OR
          nvl(i.c015, 'null') !=  OR*/
        ) then
        l_err := 1;
        
          APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE(
            p_collection_name => 'LOAD_CONTENT',
            p_seq => i.SEQ,
            p_attr_number => '20',
            p_attr_value => '_ERR'
          ); 
        end if;
          
      end loop;
      
      return l_err;
    end;
    
procedure merge_or_cancel_upload(p_assign in number, p_choice in number, p_year in number)
    as
    begin
      if(p_choice = 1) then
        insert into STP_WA_SAVE("RIN", 
                                "MUNICIPALITY", 
                                "MAIN_ROAD", 
                                "BETWEEN_1", 
                                "BETWEEN_2", 
                                "ROAD_SIDE", 
                                "BROADLEAVED_(GATOR_BAGS)", 
                                "CONIFERS", 
                                "POTTED_STOCK", 
                                "SHRUBS", 
                                "TOTAL_ITEMS", 
                                "DATE_WATERED", 
                                "TIME_WATERED_(24HR_CLOCK)", 
                                "TRUCK_ID", 
                                "WATER_COUNT_(TOTAL_WATERED)", 
                                "YR_AUDIT_WATER_COUNT_CONFIRMED", 
                                "COMMENTS", 
                                "CONTRACTOR_WATERING_ID", 
                                "LOCATION_NOTES", 
                                "SEQ_ID", 
                                "CONTRACTOR_UPLOAD_VERSION", 
                                "WATERING_ASSIGNMENT_NUM", 
                                "WATERING_ASSIGNMENT_YEAR", 
                                "OTHER_TREES", 
                                "CREATED_ON")
        select  STP_WA_SAVE."RIN", 
                STP_WA_SAVE."MUNICIPALITY", 
                STP_WA_SAVE."MAIN_ROAD", 
                STP_WA_SAVE."BETWEEN_1", 
                STP_WA_SAVE."BETWEEN_2", 
                STP_WA_SAVE."ROAD_SIDE", 
                STP_WA_SAVE."BROADLEAVED_(GATOR_BAGS)", 
                STP_WA_SAVE."CONIFERS", 
                STP_WA_SAVE."POTTED_STOCK", 
                STP_WA_SAVE."SHRUBS", 
                STP_WA_SAVE."TOTAL_ITEMS", 
                STP_CONTRACTOR_UPLOAD."DATE_WATERED",
                STP_CONTRACTOR_UPLOAD."TIME_WATERED_(24HR_CLOCK)", 
                STP_CONTRACTOR_UPLOAD."TRUCK_ID", 
                STP_CONTRACTOR_UPLOAD."WATER_COUNT_(TOTAL_WATERED)", 
                STP_CONTRACTOR_UPLOAD."YR_AUDIT_WATER_COUNT_CONFIRMED",
                STP_CONTRACTOR_UPLOAD."COMMENTS", 
                STP_CONTRACTOR_UPLOAD."CONTRACTOR_WATERING_ID", 
                nvl(null, 'TODO') as "LOCATION_NOTES",
                STP_CONTRACTOR_UPLOAD."SEQ_ID", 
                (select max(nvl(CONTRACTOR_UPLOAD_VERSION, 0)) + 1 from STP_WA_SAVE where WATERING_ASSIGNMENT_NUM = p_assign),
                p_assign, 
                p_year, 
                nvl(null, 0), 
                SYSDATE
        from STP_CONTRACTOR_UPLOAD  left join STP_WA_SAVE on STP_CONTRACTOR_UPLOAD.seq_id = STP_WA_SAVE.seq_id and STP_WA_SAVE.WATERING_ASSIGNMENT_NUM = p_assign and STP_WA_SAVE.WATERING_ASSIGNMENT_YEAR = p_year and STP_WA_SAVE.contractor_upload_version = 0;
      end if;
      
      execute immediate 'truncate table STP_CONTRACTOR_UPLOAD';
      
    end;
    
    procedure update_finalize_assignment(p_assign in number, 
                                     p_version in number,
                                     p_year in number)
    as
    begin
      update STP_WA_SAVE set FINAL = 0
      where WATERING_ASSIGNMENT_YEAR = p_year
        and WATERING_ASSIGNMENT_NUM = p_assign
        and CONTRACTOR_UPLOAD_VERSION != 0;
      
      update STP_WA_SAVE set FINAL = 1 
      where WATERING_ASSIGNMENT_NUM = p_assign
      and CONTRACTOR_UPLOAD_VERSION = p_version
      and WATERING_ASSIGNMENT_YEAR = p_year;
    end;

end;

create or replace PACKAGE BODY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     STP_WA_PKG
as


procedure load_watering_item(p_year in number) as

l_query varchar(5000);
k_query varchar(5000);
j_query varchar(5000);
i_query varchar(5000);
begin

    i_query := q'[delete from stp_wa_detail where temp_save_year =]'||p_year;
    execute immediate i_query;
    commit;
    
--insert trees from fsttree
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
                       Count(stlv.treeid) AS tree_count,
                       stlv.MUNICIPALITY as MUNICIPALITY
                --stlv.yearplanted, 
                FROM   stp_tree_watering_v stlv 
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
                          ws_road.to_street,
                          stlv.MUNICIPALITY
               order by 1) LOOP 
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
                     tree_count,
                     temp_save_year,
                    MUNICIPALITY) 
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
                     rec.tree_count,
                    p_year,
                    rec.MUNICIPALITY); 
    END LOOP; 
--insert from additional watering assignment

    FOR rec1 IN (
SELECT swai.rin    AS rin, 
               swai.roadside      AS road_side, 
               sci.year  AS contract_year, 
               sci.item_num  AS contract_item, 
               sci.MUNICIPALITY as MUNICIPALITY, 
               ws_road.full_name  AS on_street, 
               ws_road.from_street AS from_street, 
               ws_road.to_street AS to_street, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Broadleaved'
                           then qty
                     ELSE 0 
                   END)           b_tree_count, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Conifer'
                           then qty
                     ELSE 0 
                   END)           c_tree_count, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Potted' or swai.plant_type = 'Shrub' -- added shrub for other trees
                           then qty
                     ELSE 0 
                   END)           p_tree_count, 
              -- added shrub for other trees SUM(CASE 
              -- added shrub for other trees       WHEN swai.plant_type = 'Shrub'
              -- added shrub for other trees             then qty
              -- added shrub for other trees       ELSE 0 
              -- added shrub for other trees     END)           
                0 as s_tree_count, --added to change to other trees
               sum(qty) as tree_count,
               WATERING_ADDITIONAL_ITEM_ID

        FROM   stp_watering_additional_item swai -- change

        join stp_contract_item sci --change

            on swai.contract_item_id = sci.id --as contract_item change
        and (sci.year = p_year   or sci.year = p_year -1 or sci.year = p_year -2) --TODO: change to 2017 -- change
        left join ws_road
                ON swai.rin = ws_road.segmentid


        GROUP  BY swai.rin,
               swai.roadside,      
               sci.year,  
               sci.item_num,  
               sci.MUNICIPALITY, 
               ws_road.full_name,  
               ws_road.from_street, 
               ws_road.to_street,
               WATERING_ADDITIONAL_ITEM_ID
    ) LOOP 
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
                     tree_count,
                     temp_save_year,
                    MUNICIPALITY,
                    WATERING_ADDITIONAL_ITEM_ID) 
        VALUES      (rec1.rin, 
                     rec1.road_side, 
                     rec1.contract_year, 
                     rec1.contract_item, 
                     rec1.on_street, 
                     rec1.from_street, 
                     rec1.to_street, 
                     rec1.b_tree_count, 
                     rec1.c_tree_count, 
                     rec1.p_tree_count, 
                     rec1.s_tree_count, 
                     rec1.tree_count,
                     p_year,
                    rec1.MUNICIPALITY,
                    rec1.WATERING_ADDITIONAL_ITEM_ID
                    ); 
    END LOOP; 
    
--insert master rows
for rec2 in
            (select rin as rin,
                   road_side as road_side,
                   0 as b_tree_count,
                   0 as  c_tree_count,
                   0 as p_tree_count,
                   0 as s_tree_count,
                   1 as is_on_hold,
                   0 as is_assigned_total,
                   --MUNICIPALITY,
                   sum(b_tree_count) as ori_total_b,
                   sum(c_tree_count) as ori_total_c,
                   sum(p_tree_count) as ori_total_others
             from stp_wa_detail
             where temp_save_year = p_year
             group by rin,
                      road_side--,
                      --MUNICIPALITY
             union all
                        select rin as rin,
                               road_side as road_side,
                               sum(b_tree_count) as b_tree_count,
                               sum(c_tree_count) as c_tree_count,
                               sum(p_tree_count) as p_tree_count,
                               sum(s_tree_count) as s_tree_count,
                               0 as is_on_hold,
                               1 as is_assigned_total,
                               --MUNICIPALITY,
                               null as ori_total_b,
                               null as ori_total_c,
                               null as ori_total_others
                         from stp_wa_detail
                         where temp_save_year = p_year
                         group by rin,
                                  road_side--,
                                  --MUNICIPALITY
            order by  1 asc, 2asc, 7 desc)
loop
        INSERT INTO stp_wa_detail 
                    (rin, 
                     road_side, 
                     b_tree_count, 
                     c_tree_count, 
                     p_tree_count, 
                     s_tree_count, 
                     is_on_hold,
                     is_assigned_total,
                     temp_save_year,
                    --MUNICIPALITY,
                     ori_total_b,
                     ori_total_c,
                     ori_total_others
                    ) 
        VALUES      (rec2.rin, 
                     rec2.road_side, 
                     rec2.b_tree_count, 
                     rec2.c_tree_count, 
                     rec2.p_tree_count, 
                     rec2.s_tree_count, 
                     rec2.is_on_hold,
                     rec2.is_assigned_total,
                     p_year,
                     --rec2.MUNICIPALITY,
                     rec2.ori_total_b,
                     rec2.ori_total_c,
                     rec2.ori_total_others); 
end loop;
  stp_wa_pkg.restore_on_hold_and_comments(p_year);
  --update total after update on_hold record
  stp_wa_pkg.update_total(p_year);
        
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
    
    procedure restore_on_hold_and_comments(p_year in number) as
    l_query varchar(2000);
    begin
    
    --pull on_hold and comments from latest assignment step 1
    --point: right after load_watering_items 
    --process: merge to update on_hold
    --TODO: change comment source to all pull from is_on_hold = 1
    merge into stp_wa_detail new_load
      using (select   distinct stp_wa_save_on_hold.rin, 
              stp_wa_save_on_hold.road_side, 
              stp_wa_save_on_hold.b_on_hold, 
              stp_wa_save_on_hold.c_on_hold, 
              stp_wa_save_on_hold.others_on_hold,
              stp_wa_save_on_hold.ori_total_b,
              stp_wa_save_on_hold.ori_total_c,
              stp_wa_save_on_hold.ori_total_others,
              stp_wa_save_on_hold.location_notes,
              stp_wa_save_on_hold.RIN_ON_HOLD_COMMENTS
            from stp_wa_save_on_hold
            where stp_wa_save_on_hold.watering_assignment_num = (select max(watering_assignment_num) from stp_wa_save_on_hold where watering_assignment_year = p_year) 
            and stp_wa_save_on_hold.watering_assignment_year = p_year
          ) latest
      on(new_load.rin = latest.rin and new_load.road_side = latest.road_side and new_load.is_on_hold = 1 and new_load.temp_save_year = p_year)
      --when matched, update on_hold number to latest on_hold number in that rin+road_side
        when matched then
          update 
            set 
              --update rin onhold
              new_load.b_tree_count = case
                            when new_load.ori_total_b >= latest.ori_total_b then latest.b_on_hold 
                            when new_load.ori_total_b < latest.b_on_hold then 0 
                            --TODO: confirm with business side, might change to total number in rin
                          end,
              new_load.c_tree_count = case
                            when new_load.ori_total_c >= latest.ori_total_c then latest.c_on_hold
                            when new_load.ori_total_c < latest.c_on_hold then 0
                          end,
              new_load.p_tree_count = case
                            when new_load.ori_total_others >= latest.ori_total_others then latest.others_on_hold 
                            when new_load.ori_total_others < latest.others_on_hold then 0
                          end,
              --update rin new_or_updated_rin 
              /*
              new_load.new_or_updated_rin = case
                            when (new_load.ori_total_b = latest.ori_total_b) and
                               (new_load.ori_total_c = latest.ori_total_c) and
                               (new_load.ori_total_others = latest.ori_total_others)
                            then 0
                            else 2
                          end,
              */
              --update rin comments
              new_load.location_notes = latest.location_notes,
              new_load.RIN_ON_HOLD_COMMENTS = latest.RIN_ON_HOLD_COMMENTS;
              
    
    
      --when not matched (there's a new rin), keep the on_hold and do nothing  
    
    end;
    
    --set new_or_updated information before inserting to stp_wa_save
    procedure update_rin_status(p_year in number) as
    begin
    /*
    --if any contract item in a rin + roadside is updated, set is_assigned_total rin+roadside to be updated
      update stp_wa_detail each_rin
      set new_or_updated_rin = 2
      where 
        is_assigned_total = 1 and
        temp_save_year = p_year
        and new_or_updated_rin is null
        and exists (
          select *
          from stp_wa_detail 
          where rin = each_rin.rin
          and road_side = each_rin.road_side
          and new_or_updated_rin = 2
          and temp_save_year = p_year
        ); */
        
    --when total number not matched, set to 2 updated
      update stp_wa_detail each_rin
      set new_or_updated_rin = case
                            when (each_rin.b_tree_count <> (select b_assigned_total from stp_wa_save_on_hold swsoh
                                                                where swsoh.watering_assignment_year = p_year 
                                                                and swsoh.rin = each_rin.rin
                                                                and swsoh.road_side = each_rin.road_side)
                                 or each_rin.c_tree_count <> (select c_assigned_total from stp_wa_save_on_hold swsoh
                                                                where swsoh.watering_assignment_year = p_year 
                                                                and swsoh.rin = each_rin.rin
                                                                and swsoh.road_side = each_rin.road_side)
                                 or each_rin.p_tree_count <> (select others_assigned_total from stp_wa_save_on_hold swsoh
                                                                where swsoh.watering_assignment_year = p_year 
                                                                and swsoh.rin = each_rin.rin
                                                                and swsoh.road_side = each_rin.road_side))
                                 and each_rin.is_assigned_total = 1 
                                 and each_rin.temp_save_year = p_year
                            then 2 end;
                      
    
    --if there's any new rin+roadside (compared to last watering assignment, set is_assigned_total rin+roadside to be new
      update stp_wa_detail each_rin
      set new_or_updated_rin = 1
      where 
        is_assigned_total = 1 and
        temp_save_year = p_year
        and new_or_updated_rin is null
        and not exists (
          select *
          from stp_wa_save_on_hold swsoh 
          where swsoh.rin = each_rin.rin
          and swsoh.road_side = each_rin.road_side
          and swsoh.watering_assignment_year = p_year)
        and exists(select * from stp_wa_save where watering_assignment_year = p_year);
    end;
    
    
    procedure update_concat_mun(p_year in number) as
    
    begin
      merge into stp_wa_detail no_mun
      using(
      --SELECT rin, road_side, LISTAGG(convert(municipality, 'AL32UTF8', 'AL16UTF16'), ', ')
      SELECT rin, road_side, LISTAGG(municipality, ', ')
               WITHIN GROUP (ORDER BY rin, road_side) "mun_list"
               from (
                    select distinct to_char(stp_wa_detail.rin) as rin, to_char(stp_wa_detail.road_side) as road_side, to_char(stp_tree_watering_v.municipality) as municipality from stp_wa_detail  join stp_tree_watering_v
                    on stp_wa_detail.rin = stp_tree_watering_v.segment_id and stp_wa_detail.road_side = stp_tree_watering_v.roadside
                    and temp_save_year = p_year and stp_wa_detail.is_assigned_total = 1 and (stp_tree_watering_v.yearplanted = p_year or stp_tree_watering_v.yearplanted = p_year -1 or stp_tree_watering_v.yearplanted = p_year -2)
                    union all
                    select swai.rin, swai.roadside as road_side, sci.municipality as municipality
                    from stp_watering_additional_item swai join stp_contract_item sci
                    on to_char(swai.contract_item_id) = to_char(sci.id)
                    where contract_year  = p_year or contract_year = p_year - 1 or contract_year = p_year - 2
                    order by rin
                    )
               group by rin, road_side
               ) concat_mun
      on (no_mun.rin = concat_mun.rin and no_mun.road_side = concat_mun.road_side and temp_save_year = p_year and is_assigned_total = 1)
        when matched then update
          set no_mun.municipality = concat_mun."mun_list";
    end;
    
    procedure update_total(p_year in number) as
    l_query varchar(5000);
    begin
        l_query := q'[delete from stp_wa_detail where is_assigned_total = 1 and temp_save_year = ]'||p_year;
        execute immediate l_query;
        
        for rec_new_total in (
        select rin as rin,
               road_side as road_side,
               sum(b_tree_count)- (select b_tree_count from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year) as b_tree_count,
               sum(c_tree_count) - (select c_tree_count from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year)as c_tree_count,
               sum(p_tree_count) - (select p_tree_count from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year)as p_tree_count,
               sum(s_tree_count) - (select s_tree_count from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year) as s_tree_count,
               0 as is_on_hold,
               1 as is_assigned_total,
               null as ori_total_b,
               null as ori_total_c,
               null as ori_total_others,
               (select rin_on_hold_comments from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year) as rin_on_hold_comments,
               (select location_notes from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year) as location_notes,
               (select rin_comments from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year) as rin_comments
         from stp_wa_detail a
         where temp_save_year = p_year and is_on_hold is null and is_assigned_total is null
         group by rin,
                  road_side
                order by  1 asc, 2 asc, 7 desc)
    loop
        INSERT INTO stp_wa_detail 
                            (rin, 
                             road_side, 
                             b_tree_count, 
                             c_tree_count, 
                             p_tree_count, 
                             s_tree_count, 
                             is_on_hold,
                             is_assigned_total,
                             temp_save_year,
                             ori_total_b,
                             ori_total_c,
                             ori_total_others,
                             rin_on_hold_comments,
                             location_notes,
                             rin_comments
                            ) 
                VALUES      (rec_new_total.rin, 
                             rec_new_total.road_side, 
                             rec_new_total.b_tree_count, 
                             rec_new_total.c_tree_count, 
                             rec_new_total.p_tree_count, 
                             rec_new_total.s_tree_count, 
                             rec_new_total.is_on_hold,
                             rec_new_total.is_assigned_total,
                             p_year,
                             rec_new_total.ori_total_b,
                             rec_new_total.ori_total_c,
                             rec_new_total.ori_total_others,
                             rec_new_total.rin_on_hold_comments,
                             rec_new_total.location_notes,
                             rec_new_total.rin_comments); 
    end loop;
    end;
    
    
    
    procedure update_single_rin_total(p_year in number, p_rin in varchar2, p_road_side in varchar2) as
    l_query varchar(5000);
    begin
        --l_query := q'[delete from stp_wa_detail where is_assigned_total = 1 and temp_save_year = ]'||p_year||q'[and rin = ]'||p_rin||q'[and road_side = ]'||p_road_side;
        --execute immediate l_query;
        stp_wa_pkg.delete_single_rin_total(p_year, p_rin, p_road_side);
        
        for rec_new_total in (
        select rin as rin,
               road_side as road_side,
               sum(b_tree_count)- (select b_tree_count from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year) as b_tree_count,
               sum(c_tree_count) - (select c_tree_count from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year)as c_tree_count,
               sum(p_tree_count) - (select p_tree_count from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year)as p_tree_count,
               sum(s_tree_count) - (select s_tree_count from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year) as s_tree_count,
               0 as is_on_hold,
               1 as is_assigned_total,
               null as ori_total_b,
               null as ori_total_c,
               null as ori_total_others,
               (select rin_on_hold_comments from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year and rin = p_rin and road_side = p_road_side) as rin_on_hold_comments,
               (select location_notes from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year and rin = p_rin and road_side = p_road_side) as location_notes,
               (select rin_comments from stp_wa_detail b where is_on_hold = 1 and b.rin = a.rin and b.road_side = a.road_side and temp_save_year = p_year and rin = p_rin and road_side = p_road_side) as rin_comments
         from stp_wa_detail a
         where temp_save_year = p_year and is_on_hold is null and is_assigned_total is null and rin = p_rin and road_side = p_road_side
         group by rin,
                  road_side
                order by  1 asc, 2 asc, 7 desc)
    loop
        INSERT INTO stp_wa_detail 
                            (rin, 
                             road_side, 
                             b_tree_count, 
                             c_tree_count, 
                             p_tree_count, 
                             s_tree_count, 
                             is_on_hold,
                             is_assigned_total,
                             temp_save_year,
                             ori_total_b,
                             ori_total_c,
                             ori_total_others,
                             rin_on_hold_comments,
                             location_notes,
                             rin_comments,
                             new_or_updated_rin
                            ) 
                VALUES      (rec_new_total.rin, 
                             rec_new_total.road_side, 
                             rec_new_total.b_tree_count, 
                             rec_new_total.c_tree_count, 
                             rec_new_total.p_tree_count, 
                             rec_new_total.s_tree_count, 
                             rec_new_total.is_on_hold,
                             rec_new_total.is_assigned_total,
                             p_year,
                             rec_new_total.ori_total_b,
                             rec_new_total.ori_total_c,
                             rec_new_total.ori_total_others,
                             rec_new_total.rin_on_hold_comments,
                             rec_new_total.location_notes,
                             rec_new_total.rin_comments,
                             2); --new_or_updated_rin 2:updated 
    end loop;
    end;
    
    procedure delete_single_rin_total(p_year in number, p_rin in varchar2, p_road_side in varchar2) as
    begin
    delete from stp_wa_detail where is_assigned_total = 1 and temp_save_year = p_year and rin = p_rin and road_side = p_road_side;
    end;
    
    procedure insert_aw_to_wa_cur(p_year in number)  as
    begin
    --insert one detail row from new aw + existing rin and road_side added during the process of adding watering assignment

    FOR rec1 IN (
        SELECT swai.rin    AS rin, 
               swai.roadside      AS road_side, 
               sci.year  AS contract_year, 
               sci.item_num  AS contract_item, 
               sci.MUNICIPALITY as MUNICIPALITY, 
               ws_road.full_name  AS on_street, 
               ws_road.from_street AS from_street, 
               ws_road.to_street AS to_street, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Broadleaved'
                           then qty
                     ELSE 0 
                   END)           b_tree_count, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Conifer'
                           then qty
                     ELSE 0 
                   END)           c_tree_count, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Potted' or swai.plant_type = 'Shrub' -- added shrub for other trees
                           then qty
                     ELSE 0 
                   END)           p_tree_count, 
              -- added shrub for other trees SUM(CASE 
              -- added shrub for other trees       WHEN swai.plant_type = 'Shrub'
              -- added shrub for other trees             then qty
              -- added shrub for other trees       ELSE 0 
              -- added shrub for other trees     END)           
                0 as s_tree_count, --added to change to other trees
               sum(qty) as tree_count,
               WATERING_ADDITIONAL_ITEM_ID

        FROM   
        (
        --aw + existing rin and road_side added during the process of adding watering assignment
        select * from stp_watering_additional_item swai
        where not exists 
        (select watering_additional_item_id 
        from stp_wa_detail swd 
        where swd.watering_additional_item_id = swai.watering_additional_item_id)
        and exists 
        (select * from 
        stp_wa_detail swd2 
        where swd2.rin =  swai.rin and swd2.road_side =  swai.roadside)
        )
        
        swai

        join stp_contract_item sci

            on swai.contract_item_id = sci.id --as contract_item change
        and (sci.year = p_year   or sci.year = p_year -1 or sci.year = p_year -2) 
        left join ws_road
                ON swai.rin = ws_road.segmentid


        GROUP  BY swai.rin,
               swai.roadside,      
               sci.year,  
               sci.item_num,  
               sci.MUNICIPALITY, 
               ws_road.full_name,  
               ws_road.from_street, 
               ws_road.to_street,
               WATERING_ADDITIONAL_ITEM_ID
    ) LOOP 
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
                     tree_count,
                     temp_save_year,
                    MUNICIPALITY,
                    WATERING_ADDITIONAL_ITEM_ID,
                    new_or_updated_rin) 
        VALUES      (rec1.rin, 
                     rec1.road_side, 
                     rec1.contract_year, 
                     rec1.contract_item, 
                     rec1.on_street, 
                     rec1.from_street, 
                     rec1.to_street, 
                     rec1.b_tree_count, 
                     rec1.c_tree_count, 
                     rec1.p_tree_count, 
                     rec1.s_tree_count, 
                     rec1.tree_count,
                     p_year,
                    rec1.MUNICIPALITY,
                    rec1.WATERING_ADDITIONAL_ITEM_ID,
                    2
                    );
         stp_wa_pkg.update_single_rin_total(p_year, rec1.rin, rec1.road_side);
    END LOOP;
    
    --insert aw + new rin and road_side added during the process of adding watering assignment
        FOR rec2 IN (
        SELECT swai.rin    AS rin, 
               swai.roadside      AS road_side, 
               sci.year  AS contract_year, 
               sci.item_num  AS contract_item, 
               sci.MUNICIPALITY as MUNICIPALITY, 
               ws_road.full_name  AS on_street, 
               ws_road.from_street AS from_street, 
               ws_road.to_street AS to_street, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Broadleaved'
                           then qty
                     ELSE 0 
                   END)           b_tree_count, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Conifer'
                           then qty
                     ELSE 0 
                   END)           c_tree_count, 
               SUM(CASE 
                     WHEN swai.plant_type = 'Potted' or swai.plant_type = 'Shrub' -- added shrub for other trees
                           then qty
                     ELSE 0 
                   END)           p_tree_count, 
              -- added shrub for other trees SUM(CASE 
              -- added shrub for other trees       WHEN swai.plant_type = 'Shrub'
              -- added shrub for other trees             then qty
              -- added shrub for other trees       ELSE 0 
              -- added shrub for other trees     END)           
                0 as s_tree_count, --added to change to other trees
               sum(qty) as tree_count,
               WATERING_ADDITIONAL_ITEM_ID

        FROM   
        (
          --aw + new rin and road_side added during the process of adding watering assignment
          select * 
          from stp_watering_additional_item swai
          where not exists 
          (select watering_additional_item_id 
          from stp_wa_detail swd 
          where swd.watering_additional_item_id = swai.watering_additional_item_id 
          or (swd.rin = swai.rin and swd.road_side =  swai.roadside))
        )
        
        swai

        join stp_contract_item sci

            on swai.contract_item_id = sci.id --as contract_item change
        and (sci.year = p_year   or sci.year = p_year -1 or sci.year = p_year -2) 
        left join ws_road
                ON swai.rin = ws_road.segmentid


        GROUP  BY swai.rin,
               swai.roadside,      
               sci.year,  
               sci.item_num,  
               sci.MUNICIPALITY, 
               ws_road.full_name,  
               ws_road.from_street, 
               ws_road.to_street,
               WATERING_ADDITIONAL_ITEM_ID
    ) LOOP 
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
                     tree_count,
                     temp_save_year,
                    MUNICIPALITY,
                    WATERING_ADDITIONAL_ITEM_ID,
                    new_or_updated_rin) 
        VALUES      (rec2.rin, 
                     rec2.road_side, 
                     rec2.contract_year, 
                     rec2.contract_item, 
                     rec2.on_street, 
                     rec2.from_street, 
                     rec2.to_street, 
                     rec2.b_tree_count, 
                     rec2.c_tree_count, 
                     rec2.p_tree_count, 
                     rec2.s_tree_count, 
                     rec2.tree_count,
                     p_year,
                    rec2.MUNICIPALITY,
                    rec2.WATERING_ADDITIONAL_ITEM_ID,
                    1
                    );

    END LOOP;
    --insert master for aw + new rin and road_side added during the process of adding watering assignment
    stp_wa_pkg.insert_aw_new_rin_master(p_year);
    end;
    
    procedure insert_aw_new_rin_master(p_year in number)
    as
    begin
    for aw_new_rin_road_side in (
      select distinct 
              rin, 
              roadside as road_side,
              0 as b_tree_count,
              0 as  c_tree_count,
              0 as p_tree_count,
              0 as s_tree_count,
              1 as is_on_hold,
              0 as is_assigned_total,
              SUM(CASE 
                WHEN plant_type = 'Broadleaved'
                      then qty
                ELSE 0 
              END)           ori_total_b, 
              SUM(CASE 
                WHEN plant_type = 'Conifers'
                      then qty
                ELSE 0 
              END)           ori_total_c, 
              SUM(CASE 
                WHEN plant_type = 'Potted' or plant_type = 'Shrub'
                      then qty
                ELSE 0 
              END)           ori_total_others
              --sum(c_tree_count) as ori_total_c,
              --sum(p_tree_count) as ori_total_others
            from
              (select * 
                from stp_watering_additional_item swai
                where not exists 
                (select watering_additional_item_id 
                from stp_wa_detail swd 
                where swd.watering_additional_item_id = swai.watering_additional_item_id 
                or (swd.rin = swai.rin and swd.road_side =  swai.roadside))
              )
            where contract_year = p_year or contract_year = p_year -1 or contract_year = p_year -2
                       group by rin,
                                roadside
      union all
      select       distinct rin as rin,
                   roadside as road_side,
                   SUM(CASE 
                    WHEN plant_type = 'Broadleaved'
                          then qty
                    ELSE 0 
                   END)           b_tree_count, 
                   SUM(CASE 
                     WHEN plant_type = 'Conifers'
                          then qty
                     ELSE 0 
                   END)           c_tree_count, 
                   SUM(CASE 
                     WHEN plant_type = 'Potted' or plant_type = 'Shrub'
                          then qty
                    ELSE 0 
                   END)           p_tree_count,
                   0 as s_tree_count,
                   0 as is_on_hold,
                   1 as is_assigned_total,
                   --MUNICIPALITY,
                   0 as ori_total_b,
                   0 as ori_total_c,
                   0 as ori_total_others
             from (select * 
                      from stp_watering_additional_item swai
                      where not exists 
                      (select watering_additional_item_id 
                      from stp_wa_detail swd 
                      where swd.watering_additional_item_id = swai.watering_additional_item_id 
                      or (swd.rin = swai.rin and swd.road_side =  swai.roadside))
                  )
             where contract_year = p_year or contract_year = p_year -1 or contract_year = p_year -2
             group by rin,
                      roadside
                order by  1 asc, 2asc, 7 desc
      )
    loop
            INSERT INTO stp_wa_detail 
                        (rin, 
                         road_side, 
                         b_tree_count, 
                         c_tree_count, 
                         p_tree_count, 
                         s_tree_count, 
                         is_on_hold,
                         is_assigned_total,
                         temp_save_year,
                        --MUNICIPALITY,
                         ori_total_b,
                         ori_total_c,
                         ori_total_others
                        ) 
            VALUES      (aw_new_rin_road_side.rin, 
                         aw_new_rin_road_side.road_side, 
                         aw_new_rin_road_side.b_tree_count, 
                         aw_new_rin_road_side.c_tree_count, 
                         aw_new_rin_road_side.p_tree_count, 
                         aw_new_rin_road_side.s_tree_count, 
                         aw_new_rin_road_side.is_on_hold,
                         aw_new_rin_road_side.is_assigned_total,
                         p_year,
                         --rec2.MUNICIPALITY,
                         aw_new_rin_road_side.ori_total_b,
                         aw_new_rin_road_side.ori_total_c,
                         aw_new_rin_road_side.ori_total_others); 
    end loop;
        
    
    
    end;
    
    
    
    function validate_contractor_upload(p_assign in number, p_year in number) return number
    as
      l_con number;
      l_seq number;
      l_err number := 0;
    begin

      APEX_DEBUG.ENABLE (p_level => 2);
      APEX_DEBUG.LOG_MESSAGE(
      p_message => 'test',
      p_level => 2 );

      select count(*) into l_err from(
        select SEQ_ID from STP_WA_SAVE 
        where WATERING_ASSIGNMENT_NUM = p_assign
        and CONTRACTOR_UPLOAD_VERSION = 0
        and WATERING_ASSIGNMENT_YEAR = p_year
        and SEQ_ID not in(
          select c001 from apex_collections 
          where collection_name = 'LOAD_CONTENT'
        )
      );
      
      if(l_err > 0) then
        l_err := 1;
      else
        l_err := 0;
      end if;
      
      for i in (
        select SEQ_ID as "SEQ", c001 from apex_collections 
        where collection_name = 'LOAD_CONTENT'
        and c001 not in (
          select SEQ_ID from STP_WA_SAVE 
          where WATERING_ASSIGNMENT_NUM = p_assign
          and CONTRACTOR_UPLOAD_VERSION = 0
          and WATERING_ASSIGNMENT_YEAR = p_year
        )
      ) loop
        APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE(
            p_collection_name => 'LOAD_CONTENT',
            p_seq => i.SEQ,
            p_attr_number => '20',
            p_attr_value => '_ERR'
        ); 
        l_err := 1;
      end loop;
      
      /*for i in (
        select * from STP_WA_SAVE 
        where WATERING_ASSIGNMENT_NUM = p_assign
        and CONTRACTOR_UPLOAD_VERSION = 0
        and WATERING_ASSIGNMENT_YEAR = p_year
      ) loop
        if(i.SEQ_ID not in(select c001 from apex_collections 
           where collection_name = 'LOAD_CONTENT')) then
            l_err := 1;
        end if;
      end loop;
    
      for i in (
        select ac.SEQ_ID as "SEQ", ac.c001, ac.c002, ac.c003, ac.c004, 
        ac.c005, ac.c006, ac.c007,
        ac.c008, ac.c009, ac.c010,
        ac.c011, ac.c012, ac.c013,
        ac.c014, ac.c015, ac.c018, 
        ac.c019, wa.*
        from STP_WA_SAVE wa
        join apex_collections ac
        on wa.SEQ_ID = ac.c001 --and wa.CONTRACTOR_WATERING_ID = ac.c018
        and wa.WATERING_ASSIGNMENT_NUM = p_assign
        and wa.CONTRACTOR_UPLOAD_VERSION = 0
        and wa.WATERING_ASSIGNMENT_YEAR = p_year
        where ac.collection_name = 'LOAD_CONTENT'
        --and ac.c049 in ('INSERT','UPDATE', 'FAILED')
      ) loop     
        l_con := i.c011; -- contractor watering id
        l_seq := i.c001; -- sequence id of assignment ** not seq id of collection
        
        if(to_char(l_con) != to_char(l_seq) or l_con is null or l_seq is null) then -- raises error if the sequecne and contractor dont match i.e. contractor changed a field they shouldnt have
        l_err := 1;
          APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE(
            p_collection_name => 'LOAD_CONTENT',
            p_seq => i.SEQ,
            p_attr_number => '20',
            p_attr_value => '_ERR'
          ); 
        end if;
        
        --sys.dbms_output.put_line('test ' || i.c002 ||' and ' || i.MUNICIPALITY);
        --apex_debug.log_dbms_output;
        
        /*if(
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
          nvl(i.c015, 'null') !=  OR
        ) then
        l_err := 1;
        
          APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE(
            p_collection_name => 'LOAD_CONTENT',
            p_seq => i.SEQ,
            p_attr_number => '20',
            p_attr_value => '_ERR'
          ); 
        end if;
          
      end loop;*/
      sys.dbms_output.put_line(l_err);
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
                                "OTHER_TREES",
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
                STP_WA_SAVE."OTHER_TREES",
                STP_WA_SAVE."TOTAL_ITEMS", 
                STP_CONTRACTOR_UPLOAD."DATE_WATERED",
                STP_CONTRACTOR_UPLOAD."24_HR_TIME_WATERED", 
                STP_CONTRACTOR_UPLOAD."TRUCK_ID", 
                STP_CONTRACTOR_UPLOAD."TOTAL_ITEMS_REPORTED",--STP_CONTRACTOR_UPLOAD."WATER_COUNT_(TOTAL_WATERED)", 
                STP_CONTRACTOR_UPLOAD."TOTAL_ITEMS_CONFIRMED",
                STP_CONTRACTOR_UPLOAD."COMMENTS", 
                STP_CONTRACTOR_UPLOAD."CONTRACTOR_WATERING_ID", 
                STP_CONTRACTOR_UPLOAD."LOCATION_NOTES" as "LOCATION_NOTES", --change to stp_contractor_upload_location_note
                STP_CONTRACTOR_UPLOAD."SEQ_ID", 
                (select max(nvl(CONTRACTOR_UPLOAD_VERSION, 0)) + 1 from STP_WA_SAVE where WATERING_ASSIGNMENT_NUM = p_assign and watering_assignment_year = p_year),
                p_assign, 
                p_year, 
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
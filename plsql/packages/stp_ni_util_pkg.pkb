create or replace package body                                                                                                                                     stp_ni_util_pkg as

  function validate_data_range return boolean
  as
  l_range_from number          :=  apex_util.get_session_state('P52_TAG_NUM_INPUT_FROM');
  l_range_end  number          :=  apex_util.get_session_state('P52_TAG_NUM_INPUT_TO');
  l_list       varchar2(32000) :=  apex_util.get_session_state('P52_TAG_NUM_INPUT_LIST');
  l_color      varchar2(500)   :=  apex_util.get_session_state('P52_TAG_COLOR');
  l_year       number   :=  apex_util.get_session_state('P0_YEAR');
    l_count      number;
  begin

    with candidates as
    (select tag_num from
   (select rownum tag_num from dual connect by level <= l_range_end)
    where tag_num >= l_range_from
   union
   select to_number(column_value) as tag_num from table(string_fnc.to_table(l_list, ','))
    )
    select count(*) into l_count
    from candidates
    where tag_num in (select tag_num from stp_nursery_inspection where tag_color=l_color and year=l_year);

    
    
    return l_count=0;
  end;


  procedure create_or_save_tags
  as
  l_range_from   number                                                            := apex_util.get_session_state('p52_tag_num_input_from');
  l_range_end    number                                                            := apex_util.get_session_state('p52_tag_num_input_to');
  l_list         varchar2(32000)                                                   := apex_util.get_session_state('p52_tag_num_input_list');
  l_year           number                                                            := apex_util.get_session_state('p0_year');
  l_tag_date     bsmart_data.stp_nursery_inspection.tag_date%type                  := apex_util.get_session_state('p52_tag_date');
  l_stock_type   bsmart_data.stp_nursery_inspection.stock_type_id%type             := apex_util.get_session_state('p52_stock_type');
  l_plant_type   bsmart_data.stp_nursery_inspection.plant_type_id%type             := apex_util.get_session_state('p52_plant_type');
  l_species      bsmart_data.stp_nursery_inspection.species_id%type                := apex_util.get_session_state('p52_species');
  l_nursery_type   bsmart_data.stp_nursery_inspection.nursery_type%type              := apex_util.get_session_state('p52_nursery_type');
  l_farm_lot     bsmart_data.stp_nursery_inspection.lot%type                       := apex_util.get_session_state('p52_farm_lot');
  l_tag_color    bsmart_data.stp_nursery_inspection.tag_color%type                 := apex_util.get_session_state('p52_tag_color');
  l_tree_dug     bsmart_data.stp_nursery_inspection.tree_dug%type                  := apex_util.get_session_state('p52_tree_dug');
  l_stem_wrapped   bsmart_data.stp_nursery_inspection.stem_wrapped%type              := apex_util.get_session_state('p52_stem_wrapped');
  l_bud_emerged    bsmart_data.stp_nursery_inspection.buds_emerged%type              := apex_util.get_session_state('p52_bud_emerged');
  l_arcd       bsmart_data.stp_nursery_inspection.average_root_collar_depth%type := apex_util.get_session_state('p52_arcd');
  l_comments     bsmart_data.stp_nursery_inspection.comments%type                  := apex_util.get_session_state('p52_comments');
  l_stock_type_sub bsmart_data.stp_nursery_inspection.sub_stock_type_id%type         := apex_util.get_session_state('p52_stock_type_sub');
  l_plant_type_sub bsmart_data.stp_nursery_inspection.sub_plant_type_id%type         := apex_util.get_session_state('p52_plant_type_sub');
  l_species_sub    bsmart_data.stp_nursery_inspection.sub_species_id%type            := apex_util.get_session_state('p52_species_sub');
  l_id       bsmart_data.stp_nursery_inspection.id%type                    := apex_util.get_session_state('p52_id');
  begin


    /*creating new*/
    if l_id is null then

      for rec in (select tag_num from
     (select rownum tag_num from dual connect by level <= l_range_end)
      where tag_num >= l_range_from
     union
     select to_number(column_value) as tag_num from table(string_fnc.to_table(l_list, ',')))
      loop
        insert into stp_nursery_inspection 
        (status_id, year, tag_num, tag_date, stock_type_id, plant_type_id, species_id, nursery_type, lot, tag_color, tree_dug, stem_wrapped, buds_emerged, average_root_collar_depth, comments, sub_stock_type_id, sub_plant_type_id, sub_species_id)  
        values
      (1, l_year, rec.tag_num, l_tag_date, l_stock_type, l_plant_type, l_species, l_nursery_type, l_farm_lot, l_tag_color, l_tree_dug, l_stem_wrapped, l_bud_emerged, l_arcd, l_comments, l_stock_type_sub, l_plant_type_sub, l_species_sub);
      end loop;
      commit;
  /* update. */ 
  else
    update stp_nursery_inspection set 
      tag_date                  = l_tag_date,
      stock_type_id             = l_stock_type,
      plant_type_id             = l_plant_type,
      species_id                = l_species,
      nursery_type              = l_nursery_type,
      lot                       = l_farm_lot,
      tree_dug                  = l_tree_dug,
      stem_wrapped              = l_stem_wrapped,
      buds_emerged              = l_bud_emerged,
      average_root_collar_depth = l_arcd,
      comments                  = l_comments,
      sub_stock_type_id         = l_stock_type_sub,
      sub_plant_type_id         = l_plant_type_sub,
      sub_species_id            = l_species_sub
    where id=l_id;

    commit;
  end if;

  end;


  procedure group_action_on_tags (p_request in varchar2)
  as
    l_range_from   number          := apex_util.get_session_state('p53_tag_num_input_from');
    l_range_end    number          := apex_util.get_session_state('p53_tag_num_input_to');
    l_list         varchar2(32000) := apex_util.get_session_state('p53_tag_num_input_list');
    l_color          varchar2(32000) := apex_util.get_session_state('p53_tag_color');
    l_year          number          := apex_util.get_session_state('p0_year');
    l_status         number;
  begin

    -- get the status
    if p_request = 'RETIRE' then
      l_status := 3;
    else
      l_status := 1;
    end if;

    -- loop over and update.
    for rec in (select tag_num from
     (select rownum tag_num from dual connect by level <= l_range_end)
      where tag_num >= l_range_from
     union
     select to_number(column_value) as tag_num from table(string_fnc.to_table(l_list, ',')))
      loop
        update stp_nursery_inspection set status_id = l_status
        where tag_num = rec.tag_num and tag_color = l_color and year=l_year;
      end loop;

      commit; 

  end;
  

end stp_ni_util_pkg;
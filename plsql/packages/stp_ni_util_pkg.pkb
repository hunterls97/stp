create or replace package body                                                                                                             stp_ni_util_pkg as

  function validate_data_range return boolean
  as
  l_range_from number          :=  apex_util.get_session_state('P52_TAG_NUM_INPUT_FROM');
  l_range_end  number          :=  apex_util.get_session_state('P52_TAG_NUM_INPUT_TO');
  l_list       varchar2(32000) :=  apex_util.get_session_state('P52_TAG_NUM_INPUT_LIST');
  l_color      varchar2(500)   :=  apex_util.get_session_state('P52_TAG_COLOR');
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
    where tag_num in (select tag_num from stp_nursery_inspection where tag_color=l_color);

    
    
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
  

   
  procedure email_notification(   p_record_id          in stp_tree_planting_detail.id%type,
                    p_record_detail_num      in stp_tree_planting_detail.detail_num%type,
                    p_record_assignment_num    in stp_tree_planting_detail.assignment_num%type,
                    p_record_planting_status   in stp_tree_planting_detail.planting_status%type,
                    p_record_start_date      in stp_tree_planting_detail.start_date%type,
                    p_record_end_date      in stp_tree_planting_detail.end_date%type,
                    p_record_inspector     in stp_tree_planting_detail.inspector%type,
                    p_record_inspection_status in stp_tree_planting_detail.inspection_status%type,
                    p_record_contract_item_id  in stp_tree_planting_detail.contract_item_id%type,
                    p_record_status_id         in stp_tree_planting_detail.status_id%type)
  as 
    l_template stp_email_template%rowtype;
    l_status stp_status.description%type;
    l_location varchar2(32000);
    l_contract_num varchar2(300);
  begin
      -- Load template
      select * into l_template
      from stp_email_template where id = gc_nursery_email_template_id;

      -- Load Extra Data
      /*
      SELECT
      SCI.CONTRACT_ITEM_NUM,
      CASE OWNERSHIP
      WHEN 'Regional ROW' THEN REGIONAL_ROAD || ',' || BETWEEN_ROAD_1 || ' & ' ||  BETWEEN_ROAD_2
      ELSE LOCATION END AS LOCATION,
      SS_1.DESCRIPTION AS ASSIGNMENT_STATUS
      INTO l_contract_num, l_location, l_status
      FROM STP_TREE_PLANTING_DETAIL STPD
      LEFT JOIN STP_STATUS SS_1
      ON STPD.STATUS_ID = SS_1.ID
      LEFT JOIN STP_CONTRACT_ITEM SCI
      ON SCI.ID = STPD.CONTRACT_ITEM_ID
      WHERE STPD.ID= p_record_id;
      */

      select description into l_status
      from stp_status
      where id = p_record_status_id;

      select
      contract_item_num,
      case ownership
      when 'Regional ROW' then regional_road || ',' || between_road_1 || ' & ' ||  between_road_2
      else location end as location
      into l_contract_num, l_location
      from stp_contract_item
      where id = p_record_contract_item_id;

      -- Substitutions
      l_template.subject := REPLACE(l_template.subject, '##ContractItemNum##', l_contract_num);
      l_template.subject := REPLACE(l_template.subject, '##TreePlantingDetailNum##', p_record_detail_num);
      l_template.subject := REPLACE(l_template.subject, '##AssignmentStatus##', l_status);
      l_template.subject := REPLACE(l_template.subject, '##AssignmentNumber##', p_record_assignment_num);
      l_template.subject := REPLACE(l_template.subject, '##PlantingStatus##', p_record_planting_status);
      l_template.subject := REPLACE(l_template.subject, '##DatePlantedStartDate##', p_record_start_date);
      l_template.subject := REPLACE(l_template.subject, '##DatePlantedEndDate##', p_record_end_date);
      l_template.subject := REPLACE(l_template.subject, '##Inspector##', org_util_pkg.get_name(p_record_inspector));
      l_template.subject := REPLACE(l_template.subject, '##InspectionStatus##', p_record_inspection_status);
      l_template.subject := REPLACE(l_template.subject, '##Location##', l_location);

 
      l_template.template := REPLACE(l_template.template, '##ContractItemNum##', l_contract_num);
      l_template.template := REPLACE(l_template.template, '##TreePlantingDetailNum##', p_record_detail_num);
      l_template.template := REPLACE(l_template.template, '##AssignmentStatus##', l_status);
      l_template.template := REPLACE(l_template.template, '##AssignmentNumber##', p_record_assignment_num);
      l_template.template := REPLACE(l_template.template, '##PlantingStatus##',p_record_planting_status);
      l_template.template := REPLACE(l_template.template, '##DatePlantedStartDate##', p_record_start_date);
      l_template.template := REPLACE(l_template.template, '##DatePlantedEndDate##', p_record_end_date);
      l_template.template := REPLACE(l_template.template, '##Inspector##', org_util_pkg.get_name(p_record_inspector));
      l_template.template := REPLACE(l_template.template, '##InspectionStatus##', p_record_inspection_status);
      l_template.template := REPLACE(l_template.template, '##Location##', l_location);
 

      email_util_pkg.send_email(p_to => 'gary.kang@york.ca',--org_util_pkg.get_emails(p_record_inspector)),
                                p_from_address => 'gary.kang@york.ca',
                                p_from_name => 'Street Tree Planting and Establishment Contract Administration System',
                                p_subject => l_template.subject,
                                p_message => l_template.template);

  end;
end stp_ni_util_pkg;
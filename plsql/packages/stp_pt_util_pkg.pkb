CREATE OR REPLACE
PACKAGE BODY STP_PT_UTIL_PKG AS


   
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
      from stp_email_template where id =  d;

      -- Load Extra Data
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

END STP_PT_UTIL_PKG;
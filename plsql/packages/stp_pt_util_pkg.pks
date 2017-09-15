create or replace PACKAGE             STP_PT_UTIL_PKG AS 

  /* Package for contractor planting trees */
  
  -- ID in stp_email_template table.
  gc_email_noti_template_id constant number := 1;
  
  procedure email_notification(    p_record_id         in stp_tree_planting_detail.id%type,
                    p_record_detail_num      in stp_tree_planting_detail.detail_num%type,
                    p_record_assignment_num    in stp_tree_planting_detail.assignment_num%type,
                    p_record_planting_status   in stp_tree_planting_detail.planting_status%type,
                    p_record_start_date      in stp_tree_planting_detail.start_date%type,
                    p_record_end_date      in stp_tree_planting_detail.end_date%type,
                    p_record_inspector     in stp_tree_planting_detail.inspector%type,
                    p_record_inspection_status in stp_tree_planting_detail.inspection_status%type,
                    p_record_contract_item_id  in stp_tree_planting_detail.contract_item_id%type,
                    p_record_status_id         in stp_tree_planting_detail.status_id%type);

END STP_PT_UTIL_PKG;
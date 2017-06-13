create or replace package             STP_CR_UTIL_PKG as 

procedure email_notification(p_year in stp_deficiency_v.contractyear%type,
                             p_contract_item_num in stp_deficiency_v.contractitem%type,
                             p_def_stat in stp_contractor_repairs.deficiency_status%type, 
                             p_start in stp_contractor_repairs.date_s%type, 
                             p_end in stp_contractor_repairs.date_e%type, 
                             p_inspector in stp_contractor_repairs.assigned_to%type, 
                             p_inspect_stat in stp_contractor_repairs.inspection_status%type, 
                             p_loc in varchar2);

end;
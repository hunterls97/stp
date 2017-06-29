create or replace PACKAGE             STP_WI_UTIL_PKG AS 

    procedure process_form (p_id in stp_wrnty_inspection.id%type,
                            p_contract_year in stp_wrnty_inspection.contract_year%type,
                            p_contract_item_num in stp_wrnty_inspection.contract_item_num%type,
                            p_warranty_type_id in stp_wrnty_inspection.warranty_type_id%type,
                            p_warranty_inspector in stp_wrnty_inspection.warranty_inspector%type,
                            p_warrant_inspection_status in stp_wrnty_inspection.warrant_inspection_status%type,
                            p_repl_status in stp_wrnty_inspection.replacement_status%type,
                            p_repl_inspectior in stp_wrnty_inspection.replancement_inspectior%type,
                            p_repl_inspection_status in stp_wrnty_inspection.replacement_inspection_status%type);
                            
    procedure email_notification (p_contract_item_num in stp_wrnty_inspection.contract_item_num%type,
                            p_warranty_inspector in stp_wrnty_inspection.warranty_inspector%type,
                            p_warrant_inspection_status in stp_wrnty_inspection.warrant_inspection_status%type,
                            p_repl_status in stp_wrnty_inspection.replacement_status%type,
                            p_repl_inspectior in stp_wrnty_inspection.replancement_inspectior%type,
                            p_repl_inspection_status in stp_wrnty_inspection.replacement_inspection_status%type);
    
END STP_WI_UTIL_PKG;
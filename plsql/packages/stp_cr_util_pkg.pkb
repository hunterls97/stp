create or replace package body                                                                                     STP_CR_UTIL_PKG as 

    procedure email_notification(p_year in stp_deficiency_v.contractyear%type,
                             p_contract_item_num in stp_deficiency_v.contractitem%type,
                             p_def_stat in stp_contractor_repairs.deficiency_status%type, 
                             p_start in stp_contractor_repairs.date_s%type, 
                             p_end in stp_contractor_repairs.date_e%type, 
                             p_inspector in stp_contractor_repairs.assigned_to%type, 
                             p_inspect_stat in stp_contractor_repairs.inspection_status%type, 
                             p_loc in varchar2)
    as
      l_template stp_email_template%rowtype;
    begin
      sys.dbms_output.put_line('test');
      
      select * into l_template
      from stp_email_template where id = 2;
      
      
       -- Substitutions
      l_template.subject := REPLACE(l_template.subject, '##ContractYear##', p_year);
      l_template.subject := REPLACE(l_template.subject, '##ContractItemNum##', p_contract_item_num);
      l_template.subject := REPLACE(l_template.subject, '##DeficiencyStatus##', p_def_stat);
      l_template.subject := REPLACE(l_template.subject, '##RepairStartDate##', p_start);
      l_template.subject := REPLACE(l_template.subject, '##RepairEndDate##', p_end);
      l_template.subject := REPLACE(l_template.subject, '##RepairInspector##', p_inspector);
      l_template.subject := REPLACE(l_template.subject, '##RepairInspectionStatus##', p_inspect_stat);
      l_template.subject := REPLACE(l_template.subject, '##Location##', p_loc);

      l_template.template := REPLACE(l_template.template, '##ContractYear##', p_year);
      l_template.template := REPLACE(l_template.template, '##ContractItemNum##', p_contract_item_num);
      l_template.template := REPLACE(l_template.template, '##DeficiencyStatus##',p_def_stat);
      l_template.template := REPLACE(l_template.template, '##RepairStartDate##', p_start);
      l_template.template := REPLACE(l_template.template, '##RepairEndDate##', p_end);
      l_template.template := REPLACE(l_template.template, '##RepairInspector##', p_inspector);
      l_template.template := REPLACE(l_template.template, '##RepairInspectionStatus##', p_inspect_stat);
      l_template.template := REPLACE(l_template.template, '##Location##', p_loc);
      
      email_util_pkg.send_email(p_to => 'hunter.schofield@york.ca',--org_util_pkg.get_emails(p_inspector)),
                                p_from_address => 'hunter.schofield@york.ca',
                                p_from_name => 'Street Tree Planting and Establishment Contract Administration System',
                                p_subject => l_template.subject,
                                p_message => l_template.template);
    end;


end;
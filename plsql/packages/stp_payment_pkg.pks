create or replace package                                                                         stp_payment_pkg as

--finds every field that was checked by the user and inserts/ updates the STP_PAYMENT_ITEMS table accordingly
procedure process_checked_fields;

procedure process_payment;

procedure create_deficiency_snapshot(p_year in number);

procedure delete_snapshot(p_snap in number);

function AOP_payment_report
return varchar2;

function AOP_deficiency_list_report(p_snap in number)
return varchar2;

end stp_payment_pkg;
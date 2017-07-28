create or replace package                                                 STP_WA_PKG as

procedure load_watering_item;

procedure load_watering_item2(p_year in number);

procedure load_watering_item3(p_year in number);

procedure update_upd_ind;

procedure update_extra_work_detail;

function validate_contractor_upload(p_assign in number,
                                     p_year in number)
return number;

procedure merge_or_cancel_upload(p_assign in number,
                                 p_choice in number,
                                 p_year in number);
                                 
procedure update_finalize_assignment(p_assign in number, 
                                     p_version in number,
                                     p_year in number);

end;
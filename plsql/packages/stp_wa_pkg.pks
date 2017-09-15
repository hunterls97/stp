create or replace package                                                                                                                         STP_WA_PKG as



procedure load_watering_item(p_year in number);

procedure update_upd_ind;

procedure update_extra_work_detail;

procedure restore_on_hold_and_comments(p_year in number);

procedure update_total(p_year in number);

procedure update_single_rin_total(p_year in number, p_rin in varchar2, p_road_side in varchar2);

procedure delete_single_rin_total(p_year in number, p_rin in varchar2, p_road_side in varchar2);

procedure update_rin_status(p_year in number);

procedure update_concat_mun(p_year in number);

procedure insert_aw_to_wa_cur(p_year in number);

procedure insert_aw_new_rin_master(p_year in number);


function validate_contractor_upload(p_assign in number,
                                     p_year in number)

return number;

--function validate_correct_upload(p_assign in number,
--                                  p_year in number)
--return number;

procedure merge_or_cancel_upload(p_assign in number,
                                 p_choice in number,
                                 p_year in number);
                                 
procedure update_finalize_assignment(p_assign in number, 
                                     p_version in number,
                                     p_year in number);

end STP_WA_PKG;
create or replace package             STP_EW_UTIL_PKG as

procedure create_new_col( p_year in number);

procedure create_col_from_save( p_year in number);

procedure update_extra_work_detail;

procedure update_new_add_rec(p_year in number);

end;
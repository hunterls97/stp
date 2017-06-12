create or replace package                         stp_contractor_repair_pkg as

procedure ins_contractor_edits(p_id in varchar2, p_loc in varchar2, p_dstat in varchar2,
    p_date_s in date, p_date_e in date, p_assign in varchar2, p_istat in varchar2);

end stp_contractor_repair_pkg;
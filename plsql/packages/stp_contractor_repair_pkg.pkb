create or replace package body                                                                                                             stp_contractor_repair_pkg as

    procedure ins_contractor_edits(p_id in varchar2, p_loc in varchar2, p_dstat in varchar2,
    p_date_s in date, p_date_e in date, p_assign in varchar2, p_istat in varchar2)
    as

    begin
      merge into STP_CONTRACTOR_REPAIRS STPCR
      using dual
      on (STPCR.CONTRACT_ITEM_ID = p_id)
      when matched then
        update set 
                   LOCATION = p_loc,
                   DEFICIENCY_STATUS = p_dstat,
                   DATE_S = p_date_s,
                   DATE_E = p_date_e,
                   ASSIGNED_TO = p_assign,
                   INSPECTION_STATUS = p_istat
        where CONTRACT_ITEM_ID = p_id
      when not matched then
        insert (CONTRACT_ITEM_ID, LOCATION, DEFICIENCY_STATUS, DATE_S, DATE_E, ASSIGNED_TO, INSPECTION_STATUS)
        values (p_id, p_loc, p_dstat, p_date_s, p_date_e, p_assign, p_istat);
    end;

end stp_contractor_repair_pkg;
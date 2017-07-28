create or replace package                                                                                                                                     stp_contractor_repair_pkg as

/************************************************************************
/*
/* @file_name: STP_CONTRACTOR_REPAIR.pks
/* @author: Hunter Schofield
/*  
/* @description: Handles the assignment of contractors to deficiency
/* repairs. Should be moved to STP_PAYMENT_PKG and renamed to STP_IN_PKG
/* (stp inspectiong package)
/*
*************************************************************************/ 

procedure ins_contractor_edits(p_id in varchar2, p_loc in varchar2, p_dstat in varchar2,
    p_date_s in date, p_date_e in date, p_assign in varchar2, p_istat in varchar2, p_year in number);

end stp_contractor_repair_pkg;
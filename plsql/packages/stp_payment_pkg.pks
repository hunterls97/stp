create or replace package                                                                                                             stp_payment_pkg as

/**********************************************************************
/*
/* @file_name: STP_PAYMENT.pks
/* @author: Hunter Schofield
/*
/* @description: Handles payment processes for the tree planting inspection
/* section of the application.
/*
/**********************************************************************/ 

procedure process_checked_fields;

procedure process_payment(p_year in number);

procedure create_deficiency_snapshot(p_year in number);

procedure delete_snapshot(p_snap in number);

end stp_payment_pkg;
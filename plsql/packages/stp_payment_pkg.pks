create or replace package             stp_payment_pkg as

--finds every field that was checked by the user and inserts/ updates the STP_PAYMENT_ITEMS table accordingly
procedure process_checked_fields;

procedure process_payment;

end stp_payment_pkg;
CREATE OR REPLACE EDITIONABLE TRIGGER "BSMART_DATA"."STP_DEF_LIST_AUTO_ID_TRG" 
before insert on STP_DEFICIENCY_LIST_SNAPSHOTS
for each row

begin
  select STP_DEF_LIST_AUTO_ID.nextval
  into :new.ID
  from dual;
end;
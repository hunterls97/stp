with status as (
  select TREEID as "TREEID", READY_STATUS as "STATUS" from STP_DEFICIENCY_V STPD2
  where CREATEDATE = (select max(CREATEDATE) from STP_DEFICIENCY_V
  where TREEID = STPD2.TREEID)
),

uTree as (
  select distinct STPDV.TREEID as "TREEID", case STPDV.ACTIVITY_TYPE_ID
       when 1 then 'TreePlanting'
       when 2 then 'Stumping'
       when 3 then 'TransPlanting' 
       end as "ACT_TYPE"
       from STP_DEFICIENCY_V STPDV
       --left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
       where STPDV.ACTIVITY_TYPE_ID is not null
       order by TREEID asc
)


select distinct ut.TREEID as "TREEID",
       ut.ACT_TYPE as "Activity Type",
       STPDV.STOCK_TYPE ||'-'|| STPDV.PLANT_TYPE ||'-'|| TTREE.SPECIES as "ITEM",
       case when s.STATUS = 1 and (STPPI.PAYMENT_STATUS = 0 or STPPI.PAYMENT_STATUS is null) then 'Ready To Assign'
       when s.STATUS = 1 and STPPI.PAYMENT_STATUS = 1 then 'Assigned For Payment'
       else 'Not Ready' end
       as "Payment Status",
       nvl(STPPI.PAYMENT_CERT_NO, null) as "Payment Cert. No.", --null for now, probably put other value later.
       to_number(STPDV.CONTRACTITEM) as "CONTRACTITEM",
       case when STPPI.PAYMENT_STATUS = 2 then '--'
       when STPPI.PAYMENT_STATUS = 1 then 
       APEX_ITEM.CHECKBOX(1, STPDV.TREEID, 'UNCHECKED') || ' Unassign'
       else APEX_ITEM.CHECKBOX(1, STPDV.TREEID, 'UNCHECKED') || ' Assign'
       end as "Assign"
       from STP_DEFICIENCY_V STPDV --on STPDV.TREEID = ut.TREEID
       join transd.fsttree@etrans TTREE on STPDV.TREEID = TTREE.TREEID
       join uTree ut on STPDV.TREEID = ut.TREEID
       left join status s on STPDV.TREEID = s.TREEID
       left join STP_PAYMENT_ITEMS STPPI on STPDV.TREEID = STPPI.TREEID
       where STPDV.CONTRACTYEAR = :P0_YEAR
       order by TREEID asc

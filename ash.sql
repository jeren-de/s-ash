-- author Rene Jeruschkat, license: do whatever you like with it.
--
-- You need to edit this file to use it. Look for the "Start editing here" comment in line 37.
-- Once you edited that, start it: 
-- 
-- @ash <inspect_col>
-- where inspect_col is one of the decode values in line 100 and following, default is wait_class, 
-- module or sql_id are also typically good starting points



set pagesize 0
set heading off
set trimspool on
set tab off
SET SERVEROUTPUT ON FORMAT WRAPPED
set arraysize 2000
set feedback off
set termout on
set linesize 1000
set echo off
set define on
set verify off
col jsonlines format a200
col inspect_term format a1000
undef inspect_col
undef dbname
col inspect_col new_value inspect_col
col inspect_term new_value inspect_term
col dbname new_value dbname

whenever sqlerror exit 0



--------------------------------------------
-- Start editing here
--------------------------------------------

-- v_time_0         = inspection start
-- v_time_1         = inspection end
-- bucketsize       = measured in seconds, inspection_end-inspection_start must be a factor of bucketsize
--                    i.e. if you go for 60 seconds, inspection start and inspection end must have a full minute ending
--                    if you go for 3600 seconds, inspection start and inspection end must have a full hour ending
-- plus_restriction = fine tune the slice of data you are interested in, like sql_id = ... whatever columns you can filter on
def v_time_0= "(cast(TIMESTAMP '2020-03-30 00:00:00' as date))"
def v_time_1= "(cast(TIMESTAMP '2020-03-31 00:00:00' as date))"
def bucketsize = 60

def plus_restriction=" "
--def plus_restriction=" and user_id = 61 and program not in ('Toad.exe') and module not in ('DBMS_SCHEDULER') and sql_id = '9pp866suqfy70' "
--def plus_restriction=" and module = 'labs.exe'  "
--def plus_restriction=" and user_id in (29) and sql_id = '47mzm47cj0vgt' "
--def plus_restriction=" and wait_class = 'Application' and event = 'enq: TX - row lock contention' "
--def plus_restriction=" and module = 'ACME' and session_id= 961 and session_serial# = 465"
--def plus_restriction=" and module = 'ACME' and sql_id = 'fdms90t27snyg' "
--def plus_restriction=" and sql_id = 'aadmqntx70f4t' and sql_plan_hash_value = '362361703' "
--def plus_restriction=" and session_id = 47 and session_serial# = 21 "
--def plus_restriction=" and user_id = 29 and module = 'ACME' "
--def plus_restriction=" and sql_id ='1f4z57v5mh86a' "
--def plus_restriction=" and action = 'rkz_selektion_process' "
--def plus_restriction=" and event = 'log file sync' "
--def plus_restriction=" and wait_class in ('User I/O','System I/O','Network','Configuration','Commit') "

--------------------------------------------
-- Stop editing here
--------------------------------------------

-- with data as (
--   select null plsql_entry_object_id, null PLSQL_ENTRY_SUBPROGRAM_ID, null PLSQL_OBJECT_ID, null PLSQL_SUBPROGRAM_ID from dual 
--   union all
--   select 8040086 , 10 , 3365  , 2 from dual 
-- )
-- SELECT 
-- plsql_entry_object_id,PLSQL_ENTRY_SUBPROGRAM_ID,PLSQL_OBJECT_ID,PLSQL_SUBPROGRAM_ID
-- ,      ( SELECT object_name    FROM dba_procedures WHERE object_id = plsql_entry_object_id AND subprogram_id = 0) AS plsql_entry_object
-- ,      ( SELECT procedure_name FROM dba_procedures WHERE object_id = plsql_entry_object_id AND subprogram_id = plsql_entry_subprogram_id) AS plsql_entry_subprogram
-- ,      ( SELECT object_name    FROM dba_procedures WHERE object_id = plsql_object_id       AND subprogram_id = 0) AS plsql_object
-- ,      ( SELECT procedure_name FROM dba_procedures WHERE object_id = plsql_object_id       AND subprogram_id = PLSQL_SUBPROGRAM_ID) AS plsql_subprogram
-- FROM   data





def SASH="SASH."


--exit when we are not licensed to use diagnostic and tuning pack
spool am_i_licensed.sql
select case when '&SASH' = 'SASH.' or value = 'DIAGNOSTIC+TUNING' then '--noexit' else 'exit' end licensed from v$parameter where name ='control_management_pack_access';
spool off
@am_i_licensed.sql

prompt "parameter chosen: [&1]"


select
  decode(lower('&1'),
  'program'     ,'program',
  'module'      ,'nvl(module,''null'')',
  'sql_id'      ,'sql_id',
  'user'        ,'to_char(user_id)',
  'dwhuser'     ,'decode(user_id,36,''WEBABGLEICH'',1182,''HI_TC'',71,''REPORT_LESER'',151,''RMS'',260,''HI_OEM'',317,''HI_ITF'',335,''HI_STRUCTURED_PRODUCTS'',349,''HI_REPORT'',350,''HI_STAGE'',387,''OUTPUTBROKER'',581,''HI_META'',805,''HI_AB'',929,''OP_EREP'',to_char(user_id))',
  'webuser'     ,'decode(user_id,29,''ACT_LESER'',33,''WEBABGLEICH'',38,''HI_ITF'',51,''HI_SERVICE'',52,''HI_REPORT'',58,''HI_META'',84,''FIS'',96,''OP_EREP'',105,''SASH'',to_char(user_id))',
  'sodauser'    ,'decode(user_id,0,''SYS'',133,''EXT_JERUSCHKAT'',130,''SASH'',94,''ZABBIX'',135,''SASH_READ'',109,''STARUSER'',126,''NITRO_READ'',103,''ADONIS'',99,''CONFLUENCE'',122,''NITRO2'',5,''SYSTEM'',to_char(user_id))',
  'xdsauser'    ,'decode(user_id,62,''BVI_STAG'',67,''XVDSA'',45,''DMSCW'',61,''KURSE'',90,''SASH'',65,''XSDSA'',89,''OP_VISPO'',87,''FACTSET'',66,''XCDSA'',0,''SYS'',to_char(user_id))',
  'sid'         ,'to_char(session_id)',
  'serial'      ,'to_char(session_serial#)',
  'action'      ,'action',
  'hash'        ,'sql_plan_hash_value',
  'current_obj#','to_char(current_obj#)',
  'event'       ,'decode(session_state,''ON CPU'',''CPU'',event)',
  'locks'       ,'to_char(blocking_session)',
  'plan'        ,'to_char(sql_plan_hash_value)',
  'plsql'       ,'PLSQL_ENTRY_OBJECT_ID||''_''||PLSQL_ENTRY_SUBPROGRAM_ID||''_''||PLSQL_OBJECT_ID||''_''||PLSQL_SUBPROGRAM_ID',
  'decode(session_state,''ON CPU'',''CPU'',wait_class)')
  inspect_col 
from dual;

prompt "inspect_col derived from parameter: [&inspect_col]"


select 
  dbname 
from sash_targets 
where dbid = (select dbid from sash_target);

alter session set nls_numeric_characters= '.,';


with data as (
  select artefact from (
    select 
      artefact,sum(waits) waits
    from (
      select &&inspect_col artefact,1  waits from &SASH.v$active_session_history 
      where sample_time >= &v_time_0
        and sample_time  < &v_time_1 &plus_restriction
      union all
      select &&inspect_col artefact,10 waits from &SASH.dba_hist_active_sess_history 
      where sample_time >= &v_time_0
        and sample_time  < &v_time_1 &plus_restriction
      and sample_time < (select min(sample_time) from &SASH.v$active_session_history)
    ) group by artefact
    order by waits desc
  ) where rownum <= 10
)
select
  'decode(inspect_col,null,''null'','
  ||listagg(''''||artefact||''',inspect_col',',') within group (order by artefact)
  ||',''beyond_top10'')' inspect_term
from data;


prompt "inspect_term derived from parameter: [&inspect_term]"

spool stackedAreaChart.html


prompt <!DOCTYPE html>
prompt <html>
prompt <head>
prompt     <meta charset="utf-8">
prompt     <link href="nv.d3.css" rel="stylesheet" type="text/css">
prompt     <script src="d3.min.js" charset="utf-8"></script>
prompt     <script src="nv.d3.min.js"></script>
prompt     <style>
prompt         text {font: 12px sans-serif;}
prompt         svg {display: block;}
prompt         html, body, svg { margin: 0px; padding: 0px; height: 100%; width: 100%; }
prompt     </style>
prompt     <title>SASH &dbname avg &1 &plus_restriction</title>
prompt </head>
prompt <body class="with-3d-shadow with-transitions">
prompt <svg id="chart1"></svg>
prompt <script>


with timedata as (
  select
    cast(&&v_time_0 + numtodsinterval((rownum) * &bucketsize, 'SECOND') as TIMESTAMP) sample_end
  from dual connect by level <= ((&&v_time_1 - &&v_time_0)*24*60*60 / &bucketsize)
), wcdata as (
  select inspect_col wait_type from (
    select &inspect_term inspect_col from (
      select 
        &inspect_col inspect_col
      from &SASH.v$active_session_history
      where sample_time >= &v_time_0
        and sample_time  < &v_time_1 &plus_restriction
      union all
      select 
        &inspect_col inspect_col
      from &SASH.dba_hist_active_sess_history
      where sample_time >= &v_time_0
        and sample_time  < &v_time_1 &plus_restriction
    )
  ) group by inspect_col
),
jsdata as (
  select 
     sample_end
    ,wait_type
    ,sum(waits) waits
  from (
    select 
       cast(dt + numtodsinterval(secs,'SECOND') as TIMESTAMP) sample_end
      ,wait_type
      ,sum(waits)/&&bucketsize waits 
    from (
      select 
        dt,secs,&inspect_term wait_type, waits
      from (
        select 
          trunc(sample_time) dt
          ,ceil(to_number(to_char(sample_time,'SSSSS'))/&&bucketsize)*&&bucketsize secs
          ,&inspect_col inspect_col
          ,1 waits
        from &SASH.v$active_session_history
        where sample_time >= &v_time_0
          and sample_time  < &v_time_1 &plus_restriction
        union all
        select 
          trunc(sample_time) dt
          ,ceil(to_number(to_char(sample_time,'SSSSS'))/&&bucketsize)*&&bucketsize secs
          ,&inspect_col inspect_col
          ,10 waits
        from &SASH.dba_hist_active_sess_history
        where sample_time >= &v_time_0
          and sample_time  < &v_time_1 &plus_restriction
        and sample_time < (select min(sample_time) from &SASH.v$active_session_history)
      )
    ) group by dt,secs,wait_type
  ) group by sample_end,wait_type
),timejoin as (
  select 
     t.sample_end 
    ,w.wait_type
    ,nvl(d.waits,0) waits
  from timedata t
  cross join wcdata w
  left join jsdata d on (t.sample_end = d.sample_end and w.wait_type = d.wait_type)
),
jsonsorting as (
select 
   decode(row_number() over (partition by wait_type order by sample_end asc ),1,1,0) is_wc_start
  ,decode(row_number() over (partition by wait_type order by sample_end desc),1,1,0) is_wc_end 
  ,decode(row_number() over (order by wait_type asc ,sample_end asc ),1,1,0) is_start
  ,decode(row_number() over (order by wait_type desc,sample_end desc),1,1,0) is_end 
  ,row_number() over (order by wait_type asc ,sample_end asc) rn
  ,wait_type
  ,sample_end
  ,extract(day from(sys_extract_utc(sample_end) - DATE '1970-01-01')) * 86400000 
            + to_number(to_char(sys_extract_utc(sample_end), 'SSSSSFF3')) ms_since_epoch
  ,waits
from timejoin
order by wait_type,sample_end
),jsondata as (
select 
is_start,is_wc_start,is_wc_end,is_end,rn,wait_type,ms_since_epoch,waits,
      decode(is_start,1,'var ashjsondata = [')
    ||case when is_wc_start = 1 and is_start = 0 then ',' else '' end
    ||decode(is_wc_start,1,'{ "key" : "'||wait_type||'" , "values" : [')
    ||decode(is_wc_start,1,'',',')
    ||'['||ms_since_epoch||' , '||to_char(waits,'FM999999990D099','NLS_NUMERIC_CHARACTERS=''.,''')||']'
    ||decode(is_wc_end,1,']}')
    ||decode(is_end,1,'];') jsonlines
from jsonsorting order by rn
)
select jsonlines from jsondata order by rn
;

prompt     var colors = d3.scale.category20();
prompt     var chart;
prompt     nv.addGraph(function() {
prompt         chart = nv.models.stackedAreaChart()
prompt             .useInteractiveGuideline(true)
prompt             .x(function(d) { return d[0] })
prompt             .y(function(d) { return d[1] })
prompt             .controlLabels({stacked: "Stacked"})
prompt             .showControls(false) 
prompt             .duration(100);
prompt         chart.xAxis.tickFormat(function(d) { return d3.time.format("%a %d. %H:%M")(new Date(d)) });
--prompt         chart.xAxis.tickFormat(function(d) { return d3.time.format("%H:%M:%S")(new Date(d)) });
prompt         chart.yAxis.tickFormat(d3.format(",.2f"));
prompt         chart.legend.vers("furious");
prompt         d3.select("#chart1")
prompt             .datum(ashjsondata)
prompt             .transition().duration(1000)
prompt             .call(chart);
prompt         nv.utils.windowResize(chart.update);
prompt         return chart;
prompt     });
prompt </script>
prompt </body>
prompt </html>

spool off


host start stackedAreaChart.html


column rank format 99
column artefact format a40
column waits format 9999999
column total format 9999999
column "%" format 999
column sql_text format a100
column stmt format a250


set heading on
set pagesize 30

with top10 as (
  select rownum rank,artefact,waits,total,execs, round(100*waits/total) "%" from (
    select 
      artefact,sum(waits) waits,count(distinct exec_id) execs, sum(sum(waits)) over () total
    from (
      select &&inspect_col artefact,1  waits,to_char(SQL_EXEC_START,'YYYYMMDDHH24MISS')||SQL_EXEC_ID exec_id from &SASH.v$active_session_history     where sample_time between &v_time_0 and &v_time_1 &plus_restriction
      union all
      select &&inspect_col artefact,10 waits,to_char(SQL_EXEC_START,'YYYYMMDDHH24MISS')||SQL_EXEC_ID exec_id from &SASH.dba_hist_active_sess_history where sample_time between &v_time_0 and &v_time_1 &plus_restriction
      and sample_time < (select min(sample_time) from &SASH.v$active_session_history)
    ) group by artefact
    order by waits desc
  ) where rownum <= 10
)
select * from top10
union all
select max(rank)+1,'beyond_top10',min(total)-sum(waits) waits, min(total),0,round(100*(min(total)-sum(waits))/min(total)) "%" from top10
;




with top10 as (
  select rownum rank,sql_id,waits,total, round(100*waits/total) "%" from (
    select 
      sql_id,count(*) waits,sum(count(*)) over () total
    from (
      select sql_id from &SASH.v$active_session_history     where sample_time between &v_time_0 and &v_time_1 &plus_restriction
    ) group by sql_id
    order by waits desc
  ) where rownum <= 10
)
select 
   t.rank
  ,t.sql_id
  ,t.waits
  ,t.total
  ,t."%"
  ,trim(regexp_replace(q.sql_text,'[[:space:]]+',' ')) sql_text
from top10 t left join &SASH.sash_sqltxt q on (t.sql_id = q.sql_id)
union all
select max(rank)+1,'beyond_top10',min(total)-sum(waits) waits, min(total),round(100*(min(total)-sum(waits))/min(total)) "%",to_clob('') from top10
;



with top10 as (
  select rownum rank,sql_id,waits,total, round(100*waits/total) "%" from (
    select 
      sql_id,count(*) waits,sum(count(*)) over () total
    from (
      select sql_id from &SASH.v$active_session_history     where sample_time between &v_time_0 and &v_time_1 &plus_restriction
    ) group by sql_id
    order by waits desc
  ) where rownum <= 10
)
select 
  'select sql_id,sql_fulltext from v$sqlstats where sql_id in ('''||listagg(sql_id,''',''') within group (order by waits desc) ||''');' stmt
from top10;





set echo off

undef v_time_0
undef v_time_1
undef bucketsize
undef inspect_col
undef inspect_term
undef dbname
undef 1

set echo on
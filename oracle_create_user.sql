connect sys/Oradoc_db1 as sysdba
Drop user &1 cascade;

Create user &1 identified by &1 default tablespace users; 

Grant dba, resource, connect to &1;
Grant create session, grant any privilege to &1;

DROP ROLE C##ROLE_ING_WEBSPHERE_XA;
CREATE ROLE C##ROLE_ING_WEBSPHERE_XA;
GRANT SELECT ON SYS.DBA_PENDING_TRANSACTIONS TO C##ROLE_ING_WEBSPHERE_XA;
GRANT SELECT ON SYS.DBA_2PC_PENDING TO C##ROLE_ING_WEBSPHERE_XA;
GRANT EXECUTE ON SYS.DBMS_SYSTEM TO C##ROLE_ING_WEBSPHERE_XA;
GRANT SELECT ON SYS.PENDING_TRANS$ TO C##ROLE_ING_WEBSPHERE_XA;

Grant C##ROLE_ING_WEBSPHERE_XA to &1;

-- http://docs.codehaus.org/display/BTM/FAQ
grant select on sys.dba_pending_transactions to &1;
grant select on sys.pending_trans$ to &1;
grant select on sys.dba_2pc_pending to &1;
grant execute on sys.dbms_system to &1;
commit;
exit
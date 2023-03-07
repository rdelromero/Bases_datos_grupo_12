/*Desactivo un trigger que viene por defecto y que impone que �nicamente se puede
cambiar a un empleado de job_id en una sola ocasi�n, y con ello posibilito cambiar
a un empleado de job_id en dos o m�s ocasiones*/
alter trigger HR.UPDATE_JOB_HISTORY disable;

/*Funci�n que recibe un par�metro del tipo Jobs.job_id, de manera que si este par�metro
existe como job_id en la tabla JOBS, la funci�n devuelve true y false en caso contrario.*/
create or replace function existejobid(p_jobid Jobs.job_id%type)
   return boolean as
   k pls_integer := 0;
begin
   select count(*) into k from JOBS where p_jobid=job_id;
   if k=1 then
      return true;
   else
      return false;
   end if;
end existejobid;

/*Funci�n que recibe un par�metro del tipo Employees.employee_id, de manera que si este par�metro
existe como employee_id en la tabla EMPLEADOS, la funci�n devuelve true y false en caso contrario.*/
create or replace function existeempleadoid(p_empleadoid Employees.employee_id%type)
   return boolean as
   k pls_integer := 0;
begin
   select count(*) into k from EMPLOYEES where p_empleadoid=employee_id;
   if k=1 then
      return true;
   else
      return false;
   end if;
end existeempleadoid;

/*Procedimiento que recibe dos par�metros, uno del tipo Employees.employee y otro del tipo
Employees.job_id, que llama a las funciones existejobid y existempleadoid, y si ambas existen
entonces establece al par�metro del tipo Employees.job_id como nuevo job_id del empleado cuyo
employee_id se ha introducido como par�metro*/

create or replace procedure setOficio(empleadoid Employees.employee_id%type,
                             jobid Employees.job_id%type)
as
begin
   if existejobid(jobid) then
      if existeempleadoid(empleadoid) then
         update Employees set job_id = jobid where empleadoid=employee_id;
      else
         dbms_output.put_line('Ese employee_id no existe en esta base de datos.');
      end if;
   else
      if existeempleadoid(empleadoid) then
         dbms_output.put_line('Ese job_id no existe en esta base de datos.');
      else
         dbms_output.put_line('Ni ese job_id ni ese employee_id existen en esta base de datos.'); 
      end if;
   end if;
end;

/*Bloque an�nimo que pone en pr�ctica el procedimiento anterior*/
declare
   v_empleadoid Employees.job_id%type := &idempleadoaintroducir;
   v_jobid Employees.job_id%type := &idjobaintroducir;
begin
   setOficio(v_empleadoid, v_jobid);
end;
rollback;

/*Tabla EMP_AUDIT cuyos campos son employee_id, momento en el que se hace la actualizaci�n de salario,
y comentario donde se indica el salario anterior y el salario nuevo*/
drop table EMP_AUDIT;
create table EMP_AUDIT(
   employee_id smallint, momento timestamp, Comentario varchar(100)
);

/*Disparador que inmediatamente despu�s de producirse cualquier actualizaci�n en el la tabla empleados,
se pregunta si ha cambiado el salario, y si ha cambiado entonces inserta un registro en la tabla EMP_AUDIT informando:
- del empleado que ha cambiado de salario (a trav�s del campo employee_id),
- del momento en el que se ha cambiado (a trav�s de systimestamp),
- del salario anterior y del nuevo salario (a trav�s del campo salary).*/
create or replace trigger Avisonuevosalario
after update on Employees for each row
declare
begin
   if :old.salary<>:new.salary then
      insert into emp_audit values(:old.Employee_id, systimestamp, 'El salario anterior era $'||:old.Salary||' y el nuevo es $'||:new.Salary||'.');
   end if;
end;

/*Bloque an�nimo para probar que el disparador Avisonuevosalario funciona correctamente*/
declare
   v_empleadoid Employees.job_id%type := &idempleadoaintroducir;
   v_salary Employees.salary%type := &salarionuevoaintroducir;
begin
   UPDATE EMPLOYEES set salary=v_salary where Employee_id=v_empleadoid;
end;

select * from EMP_AUDIT;
rollback;

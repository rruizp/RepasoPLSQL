Practica 2 GBD

6 - Realiza los módulos de programación necesarios para que una actividad no sea realizada en una 
fecha concreta por más de 10 personas. (6 Jose Maria POSTGRES)

En ORACLE:
create or replace package Ejercicio6
as 
    TYPE TRegistro is Record
    (
        Codigo          actividadesrealizadas.CodigoActividad%type,
        NumPersonas     NUMBER,
        Fecha           DATE
    )
    v_tabla tTabla;
END;
/

create or replace trigger PorSentencia
before insert or update on ActividadesRealizadas
declare 
    cursor c_actividades2
    is 
    select Codigo, sum(NumPersonas) as NumPersonas, Fecha
    from Actividades a, ActividadesRealizadas ar
    where a.Codigo = ar.CodigoActividad
    group by Codigo, Fecha;
    i               number:=0;
    v_codigo        actividades.codigo%type;
    v_numpersonas   ActividadesRealizadas.NumPersonas%type;
    v_fecha         date;
begin
    open c_actividades2;
    fetch c_actividades2 into v_codigo,v_numpersonas,v_fecha;
    while c_actividades2%found loop
        Ejercicio6.v_tabla(i).Codigo:=v_codigo;
        Ejercicio6.v_tabla(i).NumPersonas:=v_numpersonas;
        Ejercicio6.v_tabla(i).Fecha:=v_fecha;
        i:=i + 1;
        fetch c_actividades2 into v_codigo,v_numpersonas,v_fecha;
    end loop;
    close c_actividades2;
end PorSentencia;
/

create or replace trigger PorFila
before insert or update on ActividadesRealizadas
for each row 
declare     
begin 
    for i in Ejercicio6.v_tabla.FIRST..Ejercicio6.v_tabla.LAST loop
        if Ejercicio6.v_tabla(i).Fecha = :new.Fecha and Ejercicio6.v_tabla(i).NumPersonas > 10 and Ejercicio6.v_tabla(i).Codigo = :new.CodigoActividad then
            raise_application_error(-20014,'No se puede realizar una actividad en una fecha concreta por más de 10 personas');
        end if;
    end loop;

    Ejercicio6.v_tabla(Ejercicio6.v_tabla.LAST+1).Codigo:=:new.CodigoActividad;
    Ejercicio6.v_tabla(Ejercicio6.v_tabla.LAST).NumPersonas:=:new.NumPersonas;
    Ejercicio6.v_tabla(Ejercicio6.v_tabla.LAST).Fecha:=:new.Fecha;

end PorFila;
/

En POSTGRES:

CREATE TABLE Ejercicio6(
Codigo VARCHAR,
NumPersonas NUMBER,
Fecha DATE
);

CREATE OR REPLACE FUNCTION PorSentencia RETURNS trigger AS $$
DECLARE
	cur_actividades CURSOR FOR select Codigo, sum(NumPersonas) as NumPersonas, Fecha
    from Actividades a, ActividadesRealizadas ar
    where a.Codigo = ar.CodigoActividad
    group by Codigo, Fecha;
    i               numeric:=0;
    v_codigo        actividades.codigo%type;
    v_numpersonas   ActividadesRealizadas.NumPersonas%type;
    v_fecha         date;
BEGIN
    open cur_actividades;
    fetch cur_actividades into v_codigo,v_numpersonas,v_fecha;
    while c_actividades2%found loop
        Ejercicio6.v_tabla(i).Codigo:=v_codigo;
        Ejercicio6.v_tabla(i).NumPersonas:=v_numpersonas;
        Ejercicio6.v_tabla(i).Fecha:=v_fecha;
        i:=i + 1;
        fetch c_actividades2 into v_codigo,v_numpersonas,v_fecha;
    end loop;
    close c_actividades2;
END;
$$ language plpgsql;

CREATE TRIGGER PorSentencia
BEFORE INSERT OR UPDATE ON ActividadesRealizadas
EXECUTE PROCEDURE PorSentencia();

CREATE OR REPLACE FUNCTION PorFila RETURNS trigger AS $$
DECLARE
    for i in Ejercicio6.v_tabla.FIRST..Ejercicio6.v_tabla.LAST loop
        if Ejercicio6.v_tabla(i).Fecha = new.Fecha and Ejercicio6.v_tabla(i).NumPersonas > 10 and Ejercicio6.v_tabla(i).Codigo = new.CodigoActividad then
            RAISE EXCEPTION (-20014,'No se puede realizar una actividad en una fecha concreta por más de 10 personas');
        end if;
    end loop;
    Ejercicio6.v_tabla(Ejercicio6.v_tabla.LAST+1).Codigo:=new.CodigoActividad;
    Ejercicio6.v_tabla(Ejercicio6.v_tabla.LAST).NumPersonas:=new.NumPersonas;
    Ejercicio6.v_tabla(Ejercicio6.v_tabla.LAST).Fecha:=new.Fecha;
END;
$$ language plpgsql;

CREATE TRIGGER PorFila
BEFORE INSERT OR UPDATE ON ActividadesRealizadas
FOR EACH ROW
EXECUTE PROCEDURE PorFila();

7- Realiza los módulos de programación necesarios para que los precios de un mismo tipo de 
habitación en una misma temporada crezca en función de los servicios ofrecidos de esta forma: 
Precio TI > Precio PC > Precio MP> Precio AD (7 Jose Maria)

create or replace package Ejercicio7
as 
    TYPE TRegistro is Record
    (
        TipoHabitacion          tarifas.CodigoTipohabitacion%type,
        Temporada               tarifas.CodigoTemporada%type,
        CodigoRegimen           tarifas.CodigoRegimen%type,
        Preciopordia            tarifas.Preciopordia%type
    );
    TYPE tTabla IS TABLE OF TRegistro INDEX BY BINARY_INTEGER;
    v_Facturas tTabla;
end Ejercicio7;
/

create or replace trigger PorSentencia
before insert or update on tarifas
is
	cursor c_tarifas
	is
	select CodigoTipohabitacion, CodigoTemporada, CodigoRegimen, Preciopordia
	from tarifas;
	i number:=0;
begin
	for v_tarifas in c_tarifas loop
		Ejercicio7.v_Facturas(i).TipoHabitacion:=v_tarifas.CodigoTipohabitacion;
		Ejercicio7.v_Facturas(i).Temporada:=v_tarifas.CodigoTemporada;
		Ejercicio7.v_Facturas(i).CodigoRegimen:=v_tarifas.CodigoRegimen;	
		Ejercicio7.v_Facturas(i).Preciopordia:=v_tarifas.Preciopordia;
		i:=i+1;
	end loop;
end;
/

create or replace trigger PorFila
before insert or update on tarifas
for each row
is
	v_precioti number:=0;
	v_preciopc number:=0;
	v_preciomp number:=0;
	v_precioad number:=0;
begin
	for h in Ejercicio7.v_Facturas.FIRST..Ejercicio7.v_Facturas.LAST loop
        if :new.CodigoTipohabitacion = Ejercicio7.v_Facturas(h).TipoHabitacion and :new.codigotemporada = Ejercicio7.v_Facturas(h).Temporada then
end;

create or replace procedure ActualizarPrecios(p_codigoregimen     tarifas.Codigoregimen%type,
                                              p_preciopordia      tarifas.Preciopordia%type,
                                              v_precioti          in out number,
                                              v_preciopc          in out number,
                                              v_preciomp          in out number,
                                              v_precioad          in out number)
is 
begin
    case 
        when p_codigoregimen = 'TI' then
            v_precioti:=p_preciopordia;
        when p_codigoregimen = 'PC' then
            v_preciopc:=p_preciopordia; 
        when p_codigoregimen = 'MP' then
            v_preciomp:=p_preciopordia; 
        when p_codigoregimen = 'AD' then
            v_precioad:=p_preciopordia;
        end case;
end ActualizarPrecios;
/

create or replace procedure ActualizarPrecios(p_codigoregimen     tarifas.Codigoregimen%type,
                                              p_preciopordia      tarifas.Preciopordia%type,
                                              v_precioti          in out number,
                                              v_preciopc          in out number,
                                              v_preciomp          in out number,
                                              v_precioad          in out number)
is 
begin
    case 
        when p_codigoregimen = 'TI' then
            v_precioti:=p_preciopordia;
        when p_codigoregimen = 'PC' then
            v_preciopc:=p_preciopordia; 
        when p_codigoregimen = 'MP' then
            v_preciomp:=p_preciopordia; 
        when p_codigoregimen = 'AD' then
            v_precioad:=p_preciopordia;
        end case;
end ActualizarPrecios;
/

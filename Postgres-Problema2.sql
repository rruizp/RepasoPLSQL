
CREATE OR REPLACE FUNCTION Informes(p_codigoestancia estancias.codigo%type) RETURNS varchar AS $Informes$
DECLARE
	v_totalgastos number=0;
BEGIN
	select MostrarCabecera(p_codigoestancia);
	select MostrarDatos(p_codigoestancia);
	select MostrarAlojamientos(p_codigoestancia,v_totalgastos);
	select MostrarGastosExtras(p_codigoestancia,v_totalgastos);
	select MostrarActividades(p_codigoestancia,v_totalgastos);
	return 'Importe Factura: ' || v_totalgastos;
END;
$Informes$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION MostrarCabecera(p_codigoestancia estancias.codigo%type) RETURNS varchar AS $MostrarCabecera$
BEGIN
	return 'Complejo Rural La Fuente';
	return 'Candelario(Salamanca)';
END;
$MostrarCabecera$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION MostrarDatos(p_codigoestancia estancias.codigo%type) RETURNS VARCHAR AS $MostrarDatos$
DECLARE
	v_nombre    personas.nombre%type;
    v_apellidos personas.apellidos%type;
    v_numhabitacion estancias.NumeroHabitacion%type;
    v_fechainicio   estancias.FechaInicio%type;
    v_fechafin      estancias.FechaFin%type;
    v_codregimen    estancias.codigoregimen%type;
BEGIN
	select Nombre, Apellidos, NumeroHabitacion, FechaInicio, FechaFin, CodigoRegimen into v_nombre,v_apellidos,v_numhabitacion,v_fechainicio,v_fechafin,v_codregimen
    from estancias e, personas p
    where e.NIFResponsable = p.nif
    and e.codigo = p_codigoestancia;
    return 'Codigo Estancia: '||p_codigoestancia;
    return 'Cliente: '||v_nombre||' '||v_apellidos;
    return 'Numero Habitación: '||v_numhabitacion||'   '||'Fecha Inicio: '||v_fechainicio||'   '||'Fecha Fin: '||v_fechafin;
    return 'Regimen de alojamiento: '||v_codregimen;
END;
$MostrarDatos$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION MostrarAlojamientos(p_codigoestancia estancias.codigo%type, out v_totalgastos) RETURNS VOID AS $$
DECLARE
	cur_alojamientos CURSOR FOR select t.nombre as Temporada, date_trunc('day', FechaFin) - date_trunc('day',FechaInicio) as NumDias, tar.Preciopordia as Preciopordia
    from estancias e, temporadas t, tarifas tar, regimenes r
    where e.codigoregimen = r.codigo 
    and r.codigo = tar.CodigoRegimen
    and tar.codigotemporada = t.codigo
    and e.codigo = p_codigoestancia;
    v_alojamientos NUMERIC:=0;
 begin
 	for i in cur_alojamientos loop
 		RAISE ALOJAMIENTO '% - % - %', i.Temporada, i.NumDias, i.Preciopordia*i.NumDias;
 		v_alojamientos:=v_alojamientos+(i.Preciopordia*i.NumDias);
 	end loop;
 	return 'Importe Total Alojamiento: '||v_alojamientos;
 	v_totalgastos:=v_totalgastos + v_alojamientos;
 end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION MostrarGastosExtras(p_codigoestancia estancias.codigo%type, out v_totalgastos int) RETURNS VOID AS $$
DECLARE
	cur_gastos CURSOR FOR select fecha,concepto,cuantia
    					  from gastosextras;
    v_gastos    numeric:=0;
    v_regimen   regimenes.codigo%type;
    v_fecha     gastosextras.fecha%type;
    v_concepto  gastosextras.concepto%type;
    v_cuantia   gastosextras.cuantia%type;
begin
	select ComprobarRegimen(p_codigoestancia, v_regimen);
	open cur_gastos;
	fetch c_gastos into v_fecha,v_concepto,v_cuantia;
	if c_gastos%rowcount = 0 or v_regimen = 'TI' then
		return ' '
	else
        while c_gastos%found loop
            return v_fecha||'  '||v_concepto||'  '||v_cuantia;
            v_gastos:=v_gastos + v_cuantia;
            fetch c_gastos into v_fecha,v_concepto,v_cuantia;
        end loop;
    end if;
    return 'Importe Gastos Extras: '||v_gastos;
	close c_gastos;
    v_totalgastos:=v_totalgastos + v_gastos;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION ComprobarRegimen(p_codigoestancia estancias.codigo%type, out v_regimen regimenes.codigo%type) RETURNS VARCHAR AS $$
DECLARE
	v_codigo    estancias.codigoregimen%type;
BEGIN
    select CodigoRegimen into v_codigo
    from estancias
    where codigo = p_codigoestancia;
    v_regimen:=v_codigo;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION MostrarActividades(p_codigoestancia estancias.codigo%type, v_totalgastos in out number) RETURNS VOID AS $$
DECLARE
	cur_gastos CURSOR FOR select ar.Fecha, a.Nombre, ar.NumPersonas, a.Precioporpersona
    from actividades a, actividadesrealizadas ar
    where a.Codigo = ar.CodigoActividad
    and ar.codigoestancia = p_codigoestancia;
    v_total     numeric:=0;
    v_regimen   regimenes.codigo%type;
    v_fecha     ActividadesRealizadas.fecha%type;
    v_nombre    Actividades.nombre%type;
    v_numpersonas   ActividadesRealizadas.NumPersonas%type;
    v_precio        actividades.precioporpersona%type;
BEGIN
	select ComprobarRegimen(p_codigoestancia,v_regimen);
    open c_actividades;
    fetch c_actividades into v_fecha,v_nombre,v_numpersonas,v_precio;
    if c_actividades%rowcount = 0 or v_regimen = 'TI' then
    	return ' ';
    else
        while c_actividades%found loop
            return v_fecha||'  '||v_nombre||'  '||v_numpersonas||'  '||v_numpersonas*v_precio;
            v_total:=v_total + (v_numpersonas*v_precio);
            fetch c_actividades into v_fecha,v_nombre,v_numpersonas,v_precio;
        end loop;
    end if;
    return 'Importe Totla Actividades Realizadas: '||v_total;
    close c_actividades;
    v_totalgastos:=v_totalgastos + v_total;
END;
$$ language plpgsql;
-------------------------------------------------------------------------------------
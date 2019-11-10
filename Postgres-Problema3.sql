CREATE OR REPLACE FUNCTION ControlFechaPruebaVers() RETURNS trigger AS $ControlFechaPruebaVers$
declare
	cur_fechaexp CURSOR FOR select fecha_inicio, fecha_fin
    						from experimentos
    						where codigo=new.cod_exp;
begin
	for v_fechasExp in c_fechasExp loop
		if new.fecha_prueba not between v_fechasExp.fecha_inicio and v_fechasExp.fecha_fin then
			RAISE EXCEPTION 'No puedes usar una fecha fuera del periodo de realización del experimento';
		end if;
	end loop;
end;
$ControlFechaPruebaVers$ LANGUAGE plpgsql;

CREATE TRIGGER ControlFechaPruebaVer
BEFORE INSERT OR UPDATE ON versiones
FOR EACH ROW
EXECUTE PROCEDURE ControlFechaPruebaVers();

CREATE OR REPLACE FUNCTION ControlFechaPruebaExp() RETURNS trigger AS $ControlFechaPruebaExp$
declare
	cur_fechavers CURSOR FOR select fecha_prueba
    						 from versiones
    						 where cod_exp=new.codigo;
begin
	for v_fechasvers in c_fechasvers loop
		if v_fechasvers.fecha_prueba not between new.fecha_inicio and new.fecha_fin then
			RAISE EXCEPTION 'No puedes modificar las fechas los experimentos porque hay fechas de pruebas de versiones';
		end if;
	end loop;
end;
$ControlFechaPruebaExp$ LANGUAGE plpgsql;

CREATE TRIGGER ControlFechaPruebaEx
BEFORE UPDATE ON experimentos
FOR EACH ROW
EXECUTE PROCEDURE ControlFechaPruebaExp();
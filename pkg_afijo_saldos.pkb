CREATE OR REPLACE PACKAGE BODY PEVISA.pkg_afijo_saldos AS
    c_col_vallibro  CONSTANT VARCHAR2(30) := 'VALOR LIBROS';
    c_col_depreacum CONSTANT VARCHAR2(30) := 'DEPRECIACION ACUMULADA';

    CURSOR cur_cuentas IS
        SELECT   cod_titulo, titulo, tipo, tasa
        FROM     cuenta_afijo_saldo
        ORDER BY cod_titulo;

    -- saldo_cuentas devuelve el saldo de las cuentas contables del balance de comprobacion.
    FUNCTION saldo_cuentas(
        p_ano         PLS_INTEGER
      , p_mes         PLS_INTEGER
      , p_titulo      cuenta_afijo_saldo.cod_titulo%TYPE
      , p_columna     cuenta_afijo_saldo_d.columna%TYPE
    )
        RETURN NUMBER IS
        saldo NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(cargo), 0) - NVL(SUM(abono), 0) AS saldo
        INTO   saldo
        FROM   saldos s JOIN cuenta_afijo_saldo_d c ON s.cuenta = c.ctacble
        WHERE  ano = p_ano
        AND    mes <= p_mes
        AND    c.cod_titulo = p_titulo
        AND    c.columna = p_columna;

        RETURN CASE p_columna WHEN c_col_vallibro THEN saldo WHEN c_col_depreacum THEN ABS(saldo) END;
    END;

    -- cuentas devuelve una lista de todas las cuentas de un titulo.
    FUNCTION cuentas(p_titulo cuenta_afijo_saldo.cod_titulo%TYPE)
        RETURN VARCHAR2 IS
        lista VARCHAR2(100);
    BEGIN
        SELECT LISTAGG(ctacble, '+') WITHIN GROUP (ORDER BY ctacble)
        INTO   lista
        FROM   cuenta_afijo_saldo_d
        WHERE  cod_titulo = p_titulo;

        RETURN lista;
    END;

    PROCEDURE genera_reporte(p_ano PLS_INTEGER, p_mes PLS_INTEGER) IS
        reporte tmp_reporte_afijo_saldos%ROWTYPE;
    BEGIN
        elimina_reporte(p_ano, p_mes);

        FOR r IN cur_cuentas LOOP
            reporte.cod_titulo := r.cod_titulo;
            reporte.descripcion := r.titulo;
            reporte.tipo := r.tipo;
            reporte.valor_libros := saldo_cuentas(p_ano, p_mes, r.cod_titulo, c_col_vallibro);
            reporte.depre_acum := saldo_cuentas(p_ano, p_mes, r.cod_titulo, c_col_depreacum);
            reporte.valor_neto := reporte.valor_libros - reporte.depre_acum;
            reporte.tasa_depre := r.tasa;
            reporte.cuentas := cuentas(r.cod_titulo);
            reporte.ano := p_ano;
            reporte.mes := p_mes;

            INSERT INTO tmp_reporte_afijo_saldos
            VALUES      reporte;
        END LOOP;

        COMMIT;
    END;

    PROCEDURE elimina_reporte(p_ano PLS_INTEGER, p_mes PLS_INTEGER) IS
    BEGIN
        DELETE FROM tmp_reporte_afijo_saldos;
    END;

    -- sub_total devuelve el valor total por tipo de titulo.
    FUNCTION sub_total(p_tipo VARCHAR2)
        RETURN total IS
        st total;
    BEGIN
        SELECT SUM(valor_libros), SUM(depre_acum), SUM(valor_neto)
        INTO   st
        FROM   tmp_reporte_afijo_saldos
        WHERE  tipo = p_tipo;

        RETURN st;
    END;
END pkg_afijo_saldos;
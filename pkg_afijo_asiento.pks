CREATE OR REPLACE PACKAGE pkg_afijo_asiento AS
    PROCEDURE activacion(af activo_fijo%ROWTYPE, fch DATE);
END pkg_afijo_asiento;
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS `farmadb` DEFAULT CHARACTER SET latin1 COLLATE latin1_spanish_ci;
USE `farmadb`;

CREATE USER IF NOT EXISTS 'cdc_src'@'%' IDENTIFIED BY 'cdc_src_pass';
GRANT ALL PRIVILEGES ON `farmadb`.* TO 'cdc_src'@'%';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, RELOAD, LOCK TABLES, SHOW DATABASES ON *.* TO 'cdc_src'@'%';
FLUSH PRIVILEGES;

DROP TABLE IF EXISTS `pedido_detalles`;
DROP TABLE IF EXISTS `pedidos`;
DROP TABLE IF EXISTS `productos`;
DROP TABLE IF EXISTS `categorias`;
DROP TABLE IF EXISTS `clientes`;
DROP TABLE IF EXISTS `familias`;
DROP TABLE IF EXISTS `vendedores`;

CREATE TABLE `familias` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) COLLATE latin1_spanish_ci NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_spanish_ci;

INSERT INTO `familias` (`id`, `nombre`) VALUES
(1, 'TABLETA'),
(2, 'INYECTABLE'),
(3, 'SUSPENSION');

CREATE TABLE `clientes` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) COLLATE latin1_spanish_ci NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_spanish_ci;

INSERT INTO `clientes` (`id`, `nombre`) VALUES
(1, 'UPeU'),
(2, 'San Martín');

CREATE TABLE `vendedores` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) COLLATE latin1_spanish_ci NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_spanish_ci;

INSERT INTO `vendedores` (`id`, `nombre`) VALUES
(1, 'Angel Sullon'),
(2, 'Carlos');

CREATE TABLE `categorias` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) COLLATE latin1_spanish_ci NOT NULL,
  `familia_id` int(11) NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_categorias_familia_id` (`familia_id`),
  CONSTRAINT `fk_categorias_familia_id`
    FOREIGN KEY (`familia_id`) REFERENCES `familias` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_spanish_ci;

INSERT INTO `categorias` (`id`, `nombre`, `familia_id`) VALUES
(1, 'Tableta', 1),
(2, 'Polvo para Solución Inyectable', 2),
(3, 'Solución para Perfusión', 2),
(4, 'Concentrado para Solución para Perfusión', 2),
(5, 'Suspensión Inyectable', 2),
(6, 'Tableta Recubierta', 1),
(7, 'Suspensión Oral', 3),
(8, 'Comprimido', 1);

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `codigo` varchar(100) COLLATE latin1_spanish_ci NOT NULL,
  `nombre` varchar(100) COLLATE latin1_spanish_ci NOT NULL,
  `concentracion` varchar(100) COLLATE latin1_spanish_ci DEFAULT NULL,
  `presentacion` varchar(100) COLLATE latin1_spanish_ci DEFAULT NULL,
  `fracciones` varchar(100) COLLATE latin1_spanish_ci DEFAULT NULL,
  `precio_compra` decimal(9,2) DEFAULT NULL,
  `precio_venta` decimal(9,2) DEFAULT NULL,
  `categoria_id` int(11) NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_productos_categoria_id` (`categoria_id`),
  CONSTRAINT `fk_productos_categoria_id`
    FOREIGN KEY (`categoria_id`) REFERENCES `categorias` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_spanish_ci;

INSERT INTO `productos` (`id`, `codigo`, `nombre`, `concentracion`, `presentacion`, `fracciones`, `precio_compra`, `precio_venta`, `categoria_id`) VALUES
(1, '3', 'A FOLIC', '0.5 mg', 'Caja Envase Blister Tabletas', '30', 8.00, 15.00, 1),
(2, '5', 'AB AMBROMOX', '600 mg', 'Caja Vial', '1', 7.00, 15.00, 2),
(3, '6', 'AB AMBROMOX', '1 200 mg', 'Vial + Accesorios', '1', 9.00, 16.00, 2),
(4, '95', 'ACICLOVIR', '200 mg', 'Caja Envase Blister Tabletas', '100', 6.00, 13.00, 1),
(5, '96', 'ACICLOVIR', '400 mg', 'Caja Envase Blister Tabletas', '100', 8.00, 14.00, 1),
(6, '102', 'ACICLOVIR', '200 mg', 'Caja Envase Blister Tabletas', '100', 11.00, 18.00, 1),
(7, '108', 'ACICLOVIR', '800 mg', 'Caja Envase Blister Tabletas', '10', 14.00, 23.00, 1),
(8, '138', 'ACIDO FOLICO', '0.5 mg', 'Caja Envase Blister Tabletas', '30', 1.00, 6.00, 1),
(9, '151', 'ACLASTA', '5 mg/100 mL', 'Frasco X 100 mL', '1', 19.00, 31.00, 3),
(10, '165', 'ACTEMRA', '80 mg/4 mL', 'Caja Vial X 4 mL', '1', 41.00, 59.00, 4),
(11, '166', 'ACTEMRA', '200 mg/10 mL', 'Caja Vial x 10 mL', '1', 19.00, 27.00, 4),
(12, '176', 'ACTILYSE', '50 mg', 'Vial', '1', 29.00, 41.00, 2),
(13, '180', 'ADACEL', '', 'Caja Frasco X 0.5 mL', '1', 16.00, 25.00, 5),
(14, '190', 'ADAX', '400 mg', 'Caja Envase Blister Tabletas', '60', 19.00, 27.00, 6),
(15, '191', 'ADAX', '600 mg', 'Caja Envase Blister Tabletas', '60', 24.00, 38.00, 6),
(16, '193', 'ADAX FLU', '100 mg + 15 mg/5 mL', 'Frasco X 60 mL', '1', 8.00, 15.00, 7),
(17, '194', 'ADAX FLU FORTE', '400 mg + 60 mg', 'Caja Envase Blister Tabletas', '60', 11.00, 19.00, 6),
(18, '195', 'ADAX FLU FORTE', '200 mg + 30 mg/5 mL', 'Frasco X 60 mL', '1', 15.00, 24.00, 7),
(19, '204', 'ADENEX', '5 mg', 'Caja Envase Blíster Comprimidos', '15', 6.00, 11.00, 8),
(20, '205', 'ADENEX', '5 mg', 'Caja Envase Blíster Comprimidos', '30', 10.00, 17.00, 8),
(21, '214', 'ADONA (AC 17)', '30 mg', 'Caja Envase Blister Tabletas', '10', 17.00, 26.00, 1),
(22, '228', 'AERO OM SABOR ANIS', '100 mg/mL', 'Frasco X 15 mL', '1', 13.00, 21.00, 7);

CREATE TABLE `pedidos` (
  `id` int(11) NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `fecha_confirmacion` timestamp NULL DEFAULT NULL,
  `fecha_envio` timestamp NULL DEFAULT NULL,
  `fecha_entrega` timestamp NULL DEFAULT NULL,
  `fecha_pago` timestamp NULL DEFAULT NULL,
  `estado` varchar(20) COLLATE latin1_spanish_ci DEFAULT NULL,
  `cliente_id` int(11) NOT NULL,
  `direccion` varchar(92) COLLATE latin1_spanish_ci DEFAULT NULL,
  `vendedor_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pedidos_cliente_id` (`cliente_id`),
  KEY `idx_pedidos_vendedor_id` (`vendedor_id`),
  CONSTRAINT `fk_pedidos_cliente_id`
    FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pedidos_vendedor_id`
    FOREIGN KEY (`vendedor_id`) REFERENCES `vendedores` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_spanish_ci;

INSERT INTO `pedidos` (`id`, `fecha_creacion`, `fecha_confirmacion`, `fecha_envio`, `fecha_entrega`, `fecha_pago`, `estado`, `cliente_id`, `direccion`, `vendedor_id`) VALUES
(1, '2020-03-08 08:09:00', '2020-03-08 09:09:00', '2020-03-08 10:09:00', '2020-03-09 08:09:00', NULL, 'Entregado', 1, 'Juliaca P#25', 1),
(2, '2020-03-08 08:29:00', '2020-03-08 10:19:00', '2020-03-08 12:19:00', '2020-03-09 07:09:00', '2020-03-11 18:09:00', 'Pagado', 2, 'Juliaca P#26', 2);

CREATE TABLE `pedido_detalles` (
  `pedido_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad` decimal(9,2) NOT NULL,
  `precio_compra_unitario` decimal(9,2) DEFAULT NULL,
  `precio_venta_unitario` decimal(9,2) NOT NULL,
  `total_descuento_unitario` decimal(9,2) DEFAULT NULL,
  `igv_unitario` decimal(9,2) DEFAULT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`pedido_id`, `producto_id`),
  KEY `idx_pedido_detalles_producto_id` (`producto_id`),
  CONSTRAINT `fk_pedido_detalles_pedido_id`
    FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pedido_detalles_producto_id`
    FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_spanish_ci;

INSERT INTO `pedido_detalles` (`pedido_id`, `producto_id`, `cantidad`, `precio_compra_unitario`, `precio_venta_unitario`, `total_descuento_unitario`, `igv_unitario`) VALUES
(1, 1, 80.00, 8.00, 15.00, 1.00, 2.52),
(1, 2, 60.00, 7.00, 15.00, 0.50, 2.61),
(1, 3, 80.00, 9.00, 16.00, 0.00, 2.88),
(2, 2, 60.00, 7.00, 15.00, 1.00, 2.52),
(2, 3, 50.00, 9.00, 16.00, 0.00, 2.88),
(2, 4, 80.00, 6.00, 13.00, 0.00, 2.34);

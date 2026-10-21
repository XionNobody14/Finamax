import 'package:flutter/material.dart';

/// Paleta oficial de FinamaX
/// Estilo "Earthy Organic / Botanical Warmth": Color hueso, verde botánico y café terroso.
class AppColors {
  // Fondos y Superficies
  static const Color background = Color(0xFFF9F7F2);            // Color hueso / lino natural claro
  static const Color backgroundSecondary = Color(0xFFF5F3EC);   // Hueso suave de soporte
  static const Color surface = Color(0xFFFCFBF9);               // Blanco marfil cálido
  static const Color surfaceCard = Color(0xFFFFFFFF);           // Superficie de tarjetas limpia
  static const Color surfaceElevated = Color(0xFFF2EFE9);       // Superficie sutilmente contrastada
  static const Color border = Color(0xFFE6E1D8);                // Borde suave orgánico
  static const Color borderLight = Color(0xFFECE7DF);

  // Acentos Botánicos y Terrosos
  static const Color forestGreen = Color(0xFF2E5339);           // Verde bosque suave (botones principales, ingresos)
  static const Color forestGreenLight = Color(0xFF456B51);      // Acento verde salvia
  static const Color forestGreenMuted = Color(0xFFE7EFE9);      // Fondo suave de badges de meta
  
  static const Color earthBrown = Color(0xFF6E4B33);            // Café cálido tostado (encabezados secundarios)
  static const Color earthBrownLight = Color(0xFF8B5E3C);       // Café arcilla medio
  static const Color earthBrownMuted = Color(0xFFF5EDE8);       // Fondo suave para badges café

  static const Color warmAmber = Color(0xFFB47214);             // Ámbar tostado para advertencias de cortes
  static const Color warmAmberMuted = Color(0xFFFDF5E8);

  static const Color terracottaRed = Color(0xFFB33A2B);         // Terracota / Rojo tierra para gastos
  static const Color terracottaMuted = Color(0xFFFBECE9);

  // Textos y Neutros Orgánicos
  static const Color textPrimary = Color(0xFF2B2C28);           // Carbón orgánico profundo para máxima legibilidad
  static const Color textSecondary = Color(0xFF766E65);         // Café apagado para subtítulos y fechas
  static const Color textMuted = Color(0xFF9E958A);             // Muted warm stone
  static const Color textDisabled = Color(0xFFC4BCB0);

  // Sombras orgánicas suaves (bajo contraste)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A2B2C28),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D2B2C28),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  // Gradientes sutiles
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2E5339), Color(0xFF1E3926)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient earthGradient = LinearGradient(
    colors: [Color(0xFF8B5E3C), Color(0xFF6E4B33)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

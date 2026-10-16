using System;

namespace Coreo.Optics
{
    public static class ToricLensPower
    {
        public const double DefaultAxisDegrees = 0.0;

        public static double NormalizeAxis(double axisDegrees)
        {
            ValidateFinite(axisDegrees, nameof(axisDegrees));

            double normalized = axisDegrees % 180.0;
            if (normalized < 0.0)
            {
                normalized += 180.0;
                if (normalized >= 180.0)
                {
                    normalized = Math.BitDecrement(180.0);
                }
            }

            return normalized == 0.0 ? 0.0 : normalized;
        }

        public static double GetPowerAtMeridian(
            double sphere,
            double cylinder,
            double thetaDegrees,
            double axisDegrees = DefaultAxisDegrees)
        {
            ValidateFinite(sphere, nameof(sphere));
            ValidateFinite(cylinder, nameof(cylinder));
            ValidateFinite(thetaDegrees, nameof(thetaDegrees));

            double normalizedAxis = NormalizeAxis(axisDegrees);
            double radians = (thetaDegrees - normalizedAxis) * (Math.PI / 180.0);
            double sine = Math.Sin(radians);

            return sphere + cylinder * sine * sine;
        }

        private static void ValidateFinite(double value, string parameterName)
        {
            if (double.IsNaN(value) || double.IsInfinity(value))
            {
                throw new ArgumentOutOfRangeException(parameterName, "Value must be finite.");
            }
        }
    }
}

using System;
using System.Security.Cryptography.X509Certificates;

namespace Coreo.Optics
{
    public static class ToricLensPower
    {
        public const double DefaultAxisDegrees = 0.0;

        public static double NormalizeAxis(double axisDegrees)
        {
            EnsureFinite(axisDegrees, nameof(axisDegrees));

            double normalizedAxis = axisDegrees % 180.0;
            if (normalizedAxis < 0.0)
            {
                normalizedAxis += 180.0;
            }

            if (normalizedAxis >= 180.0)
            {
                normalizedAxis = Math.BitDecrement(180.0);
            }

            return normalizedAxis == 0.0 ? 0.0 : normalizedAxis;
        }

        public static double GetPowerAtMeridian(double sphere, double cylinder, double meridianDegrees)
        {
            return GetPowerAtMeridian(sphere, cylinder, meridianDegrees, DefaultAxisDegrees);
        }

        public static double GetPowerAtMeridian(
            double sphere,
            double cylinder,
            double meridianDegrees,
            double axisDegrees)
        {
            EnsureFinite(sphere, nameof(sphere));
            EnsureFinite(cylinder, nameof(cylinder));
            EnsureFinite(meridianDegrees, nameof(meridianDegrees));

            double normalizedAxis = NormalizeAxis(axisDegrees);
            double radians = (meridianDegrees - normalizedAxis) * Math.PI / 180.0;
            double sine = Math.Sin(radians);
            double power = sphere + (cylinder * sine * sine);

            if (double.IsNaN(power) || double.IsInfinity(power))
            {
                throw new ArithmeticException("The calculated lens power is not finite.");
            }

            return power;
        }

        private static void EnsureFinite(double value, string parameterName)
        {
            if (double.IsNaN(value) || double.IsInfinity(value))
            {
                throw new ArgumentOutOfRangeException(parameterName, "Values must be finite.");
            }
        }
    }

    public sealed class CertificateStoreSummary
    {
        public string Location { get; private set; }
        public string Store { get; private set; }
        public int CertificateCount { get; private set; }

        internal CertificateStoreSummary(string location, string store, int certificateCount)
        {
            Location = location;
            Store = store;
            CertificateCount = certificateCount;
        }
    }

    public static class ReadOnlyCertificateStoreAudit
    {
        private static readonly StoreName[] StoreNames =
        {
            StoreName.AddressBook,
            StoreName.AuthRoot,
            StoreName.CertificateAuthority,
            StoreName.Disallowed,
            StoreName.My,
            StoreName.Root,
            StoreName.TrustedPeople,
            StoreName.TrustedPublisher
        };

        private static readonly StoreLocation[] StoreLocations =
        {
            StoreLocation.CurrentUser,
            StoreLocation.LocalMachine
        };

        public static CertificateStoreSummary[] GetSummary()
        {
            CertificateStoreSummary[] summaries =
                new CertificateStoreSummary[StoreNames.Length * StoreLocations.Length];
            int summaryIndex = 0;

            foreach (StoreLocation location in StoreLocations)
            {
                foreach (StoreName storeName in StoreNames)
                {
                    using (X509Store store = new X509Store(storeName, location))
                    {
                        store.Open(OpenFlags.ReadOnly);
                        summaries[summaryIndex++] = new CertificateStoreSummary(
                            location.ToString(),
                            storeName.ToString(),
                            store.Certificates.Count);
                    }
                }
            }

            return summaries;
        }
    }
}

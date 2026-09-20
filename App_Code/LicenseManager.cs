using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net.NetworkInformation;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using Microsoft.Win32;

/// <summary>
/// Core cryptographic licensing engine for the iDash Integrated Intelligence Hub.
/// Supports both offline air-gapped activation and online activation via RSA-2048 / SHA-256 signatures.
/// </summary>
public static class LicenseManager
{
    // Embedded RSA-2048 Public Key for digital signature verification
    private const string PublicKeyXml =
        "<RSAKeyValue><Modulus>sawNm7TQnrA+6/IVeuMvR4BFrgSK8yzI6MgxyKOtAWKMQ9CNbLr/ZSY/RUFibHzA7sHTxH2JYY6mFbFuYH2N/uXzsmeIOnl8nk7hIwhA5bto23dR7n+V2pmZx6RjRjQEyodCSDfzMMAlpEwNc91CzzA8E5f9KVUyrx8ydzUlGiKWcjM12E38NJmYTH3GH5nY1OFZmFHJhppSQeYazUoCVZW9FDK8mh2FrFR1rUeeVzZ/XmlMeqeV8uC5iLy1ToopKUMyN9rZzKieX6pfHacfVkCcXzTX4B8XTwUxk519PKhR0y7TbEWO2WW9Ag49U5vpbpwkqyZ0KIh2yq6FY5Q4FQ==</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>";

    private const string KeyPrefix = "IDASH-LIC-v1-";
    private static readonly object _syncLock = new object();
    private static LicenseValidationResult _cachedResult = null;
    private static DateTime _lastCacheCheck = DateTime.MinValue;

    // -------------------------------------------------------------------
    // Data Models
    // -------------------------------------------------------------------
    [Serializable]
    public class IdashLicensePayload
    {
        public string LicenseId      { get; set; }
        public string Customer       { get; set; }
        public string SiteName       { get; set; }
        public string StationNumber  { get; set; }
        public string HardwareId     { get; set; }
        public string LicenseType    { get; set; } // Perpetual | Annual | Trial
        public string IssuedDate     { get; set; }
        public string ExpirationDate { get; set; }
        public List<string> Features { get; set; }

        public IdashLicensePayload()
        {
            Features = new List<string>();
        }
    }

    [Serializable]
    public class LicenseEnvelope
    {
        public int Version         { get; set; }
        public string Algorithm    { get; set; }
        public string Payload      { get; set; }
        public string Signature    { get; set; }
    }

    public class LicenseValidationResult
    {
        public bool IsValid                  { get; set; }
        public string StatusReason           { get; set; }
        public string StatusDisplay          { get; set; }
        public IdashLicensePayload Payload   { get; set; }
        public string RawKeyString           { get; set; }
        public DateTime? ExpirationUtc       { get; set; }
        public int? DaysRemaining            { get; set; }
        public bool IsPerpetual              { get; set; }
    }

    public class HardwareIdentity
    {
        public string PrimaryMac             { get; set; }
        public List<string> AllMacAddresses  { get; set; }
        public string MachineGuid            { get; set; }
        public string InstallationId         { get; set; }
        public string MachineName            { get; set; }
    }

    // -------------------------------------------------------------------
    // Storage Paths
    // -------------------------------------------------------------------
    private static string LicenseFilePath
    {
        get
        {
            string appData = HttpContext.Current != null
                ? HttpContext.Current.Server.MapPath("~/App_Data")
                : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "App_Data");

            if (!Directory.Exists(appData)) Directory.CreateDirectory(appData);
            return Path.Combine(appData, "idash_license.json");
        }
    }

    private static string ClockStateFilePath
    {
        get
        {
            string appData = Path.GetDirectoryName(LicenseFilePath);
            return Path.Combine(appData, "idash_clock_state.dat");
        }
    }

    // -------------------------------------------------------------------
    // Hardware Identity & Fingerprinting
    // -------------------------------------------------------------------
    public static HardwareIdentity GetHardwareIdentity()
    {
        var id = new HardwareIdentity
        {
            AllMacAddresses = new List<string>(),
            MachineName     = Environment.MachineName
        };

        // 1. Gather Physical MAC Addresses
        try
        {
            var interfaces = NetworkInterface.GetAllNetworkInterfaces()
                .Where(nic => nic.NetworkInterfaceType != NetworkInterfaceType.Loopback
                           && nic.NetworkInterfaceType != NetworkInterfaceType.Tunnel
                           && !nic.Description.ToLowerInvariant().Contains("virtual")
                           && !nic.Description.ToLowerInvariant().Contains("pseudo")
                           && !nic.Description.ToLowerInvariant().Contains("km-test")
                           && nic.OperationalStatus == OperationalStatus.Up)
                .OrderBy(nic => nic.NetworkInterfaceType == NetworkInterfaceType.Ethernet ? 0 : 1)
                .ToList();

            if (!interfaces.Any())
            {
                // Fallback to any interface with a physical address
                interfaces = NetworkInterface.GetAllNetworkInterfaces()
                    .Where(nic => nic.GetPhysicalAddress().GetAddressBytes().Length == 6)
                    .ToList();
            }

            foreach (var nic in interfaces)
            {
                string rawMac = nic.GetPhysicalAddress().ToString().ToUpper();
                if (!string.IsNullOrEmpty(rawMac) && rawMac.Length == 12 && !id.AllMacAddresses.Contains(rawMac))
                {
                    id.AllMacAddresses.Add(rawMac);
                }
            }

            id.PrimaryMac = id.AllMacAddresses.FirstOrDefault() ?? "000000000000";
        }
        catch
        {
            id.PrimaryMac = "000000000000";
        }

        // 2. Machine GUID from Registry
        try
        {
            using (var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Cryptography"))
            {
                if (key != null)
                {
                    id.MachineGuid = Convert.ToString(key.GetValue("MachineGuid"));
                }
            }
        }
        catch
        {
            id.MachineGuid = "";
        }

        // 3. Format Installation ID (IDASH-XXXX-XXXX-XXXX)
        string composite = string.Format("{0}|{1}|{2}", id.PrimaryMac, id.MachineGuid, id.MachineName);
        using (var sha = SHA256.Create())
        {
            byte[] hash = sha.ComputeHash(Encoding.UTF8.GetBytes(composite));
            string hashHex = BitConverter.ToString(hash).Replace("-", "").ToUpper();
            
            // Format: IDASH-{MAC_FIRST4}-{MAC_LAST4}-{HASH4}
            string p1 = id.PrimaryMac.Length >= 4 ? id.PrimaryMac.Substring(0, 4) : "0000";
            string p2 = id.PrimaryMac.Length >= 8 ? id.PrimaryMac.Substring(id.PrimaryMac.Length - 4) : "0000";
            string p3 = hashHex.Substring(0, 4);

            id.InstallationId = string.Format("IDASH-{0}-{1}-{2}", p1, p2, p3);
        }

        return id;
    }

    // -------------------------------------------------------------------
    // License Validation
    // -------------------------------------------------------------------
    public static LicenseValidationResult ValidateLicense(string keyString)
    {
        var result = new LicenseValidationResult
        {
            IsValid       = false,
            RawKeyString  = keyString,
            StatusReason  = "Unknown error",
            StatusDisplay = "Unlicensed"
        };

        if (string.IsNullOrWhiteSpace(keyString))
        {
            result.StatusReason  = "License key string is empty.";
            result.StatusDisplay = "No License Applied";
            return result;
        }

        keyString = keyString.Trim();
        if (!keyString.StartsWith(KeyPrefix, StringComparison.OrdinalIgnoreCase))
        {
            result.StatusReason  = "Invalid license key format (missing required IDASH-LIC prefix).";
            result.StatusDisplay = "Invalid Format";
            return result;
        }

        string b64Envelope = keyString.Substring(KeyPrefix.Length);
        LicenseEnvelope envelope = null;
        try
        {
            byte[] envBytes = Convert.FromBase64String(b64Envelope);
            string envJson  = Encoding.UTF8.GetString(envBytes);
            envelope        = new JavaScriptSerializer().Deserialize<LicenseEnvelope>(envJson);
        }
        catch (Exception ex)
        {
            result.StatusReason  = "Failed to parse license envelope: " + ex.Message;
            result.StatusDisplay = "Corrupt Envelope";
            return result;
        }

        if (envelope == null || string.IsNullOrEmpty(envelope.Payload) || string.IsNullOrEmpty(envelope.Signature))
        {
            result.StatusReason  = "License envelope is missing payload or digital signature.";
            result.StatusDisplay = "Incomplete Envelope";
            return result;
        }

        // 1. Verify RSA Signature using Public Key
        byte[] payloadBytes   = Convert.FromBase64String(envelope.Payload);
        byte[] signatureBytes = Convert.FromBase64String(envelope.Signature);

        bool signatureValid = false;
        try
        {
            using (var rsa = new RSACryptoServiceProvider())
            {
                rsa.FromXmlString(PublicKeyXml);
                signatureValid = rsa.VerifyData(payloadBytes, CryptoConfig.MapNameToOID("SHA256"), signatureBytes);
            }
        }
        catch (Exception ex)
        {
            result.StatusReason  = "Cryptographic signature validation error: " + ex.Message;
            result.StatusDisplay = "Signature Error";
            return result;
        }

        if (!signatureValid)
        {
            result.StatusReason  = "Digital signature verification failed. The license key has been tampered with or was not issued by an authorized private key.";
            result.StatusDisplay = "Invalid Signature (Tampered)";
            return result;
        }

        // 2. Parse Payload JSON
        IdashLicensePayload payload = null;
        try
        {
            string payloadJson = Encoding.UTF8.GetString(payloadBytes);
            payload = new JavaScriptSerializer().Deserialize<IdashLicensePayload>(payloadJson);
        }
        catch (Exception ex)
        {
            result.StatusReason  = "Failed to deserialize license payload: " + ex.Message;
            result.StatusDisplay = "Invalid Payload";
            return result;
        }

        result.Payload = payload;

        // 3. Hardware ID Matching
        var hw = GetHardwareIdentity();
        string cleanLicHw = (payload.HardwareId ?? "").ToUpper().Replace(":", "").Replace("-", "").Trim();

        bool hwMatch = false;
        if (cleanLicHw == "*" || string.IsNullOrEmpty(cleanLicHw))
        {
            // Wildcard: allows any machine (e.g. site-wide or enterprise license)
            hwMatch = true;
        }
        else
        {
            // Check primary MAC, any active MAC, or InstallationId
            if (hw.AllMacAddresses.Contains(cleanLicHw) || hw.PrimaryMac == cleanLicHw)
            {
                hwMatch = true;
            }
            else if (cleanLicHw.Equals(hw.InstallationId.Replace("-", ""), StringComparison.OrdinalIgnoreCase) ||
                     cleanLicHw.Equals(hw.InstallationId, StringComparison.OrdinalIgnoreCase))
            {
                hwMatch = true;
            }
        }

        if (!hwMatch)
        {
            result.StatusReason = string.Format(
                "Hardware fingerprint mismatch. This license is locked to Hardware ID '{0}', but this machine has MAC '{1}' (Installation ID: '{2}').",
                payload.HardwareId, hw.PrimaryMac, hw.InstallationId);
            result.StatusDisplay = "Hardware Mismatch";
            return result;
        }

        // 4. Expiration Date Check
        if (!string.IsNullOrWhiteSpace(payload.ExpirationDate))
        {
            DateTime expDate;
            if (DateTime.TryParse(payload.ExpirationDate, out expDate))
            {
                result.ExpirationUtc = expDate.ToUniversalTime();
                result.IsPerpetual   = false;

                if (DateTime.UtcNow > expDate.ToUniversalTime().AddDays(1)) // 1 day grace boundary
                {
                    result.StatusReason  = string.Format("License expired on {0:yyyy-MM-dd}.", expDate);
                    result.StatusDisplay = "Expired";
                    return result;
                }

                result.DaysRemaining = (int)Math.Ceiling((expDate.ToUniversalTime() - DateTime.UtcNow).TotalDays);
            }
        }
        else
        {
            result.IsPerpetual   = true;
            result.DaysRemaining = null;
        }

        // 5. Anti-Tamper Clock Rollback Detection
        string clockErr;
        if (!CheckSystemClockIntegrity(out clockErr))
        {
            result.StatusReason  = clockErr;
            result.StatusDisplay = "Clock Tampering Detected";
            return result;
        }

        // All checks passed!
        result.IsValid       = true;
        result.StatusReason  = "License is active and valid.";
        result.StatusDisplay = result.IsPerpetual ? "Active (Perpetual)" : string.Format("Active ({0} days remaining)", result.DaysRemaining);

        return result;
    }

    // -------------------------------------------------------------------
    // Active License Retrieval & Caching
    // -------------------------------------------------------------------
    public static LicenseValidationResult GetActiveLicense(bool forceRefresh = false)
    {
        lock (_syncLock)
        {
            if (!forceRefresh && _cachedResult != null && (DateTime.UtcNow - _lastCacheCheck).TotalSeconds < 30)
            {
                return _cachedResult;
            }

            string rawKey = LoadStoredKey();
            if (string.IsNullOrEmpty(rawKey))
            {
                _cachedResult = new LicenseValidationResult
                {
                    IsValid       = false,
                    StatusReason  = "No license key installed on this system.",
                    StatusDisplay = "Unlicensed"
                };
            }
            else
            {
                _cachedResult = ValidateLicense(rawKey);
            }

            _lastCacheCheck = DateTime.UtcNow;
            return _cachedResult;
        }
    }

    public static bool IsLicensed()
    {
        return GetActiveLicense().IsValid;
    }

    public static bool CanAccessFeature(string featureCode)
    {
        var lic = GetActiveLicense();
        if (!lic.IsValid || lic.Payload == null) return false;
        if (lic.Payload.Features == null || !lic.Payload.Features.Any()) return true; // all if empty
        return lic.Payload.Features.Contains("*") || lic.Payload.Features.Contains(featureCode, StringComparer.OrdinalIgnoreCase);
    }

    // -------------------------------------------------------------------
    // License Application
    // -------------------------------------------------------------------
    public static LicenseValidationResult ApplyLicense(string keyString)
    {
        var result = ValidateLicense(keyString);
        if (!result.IsValid)
        {
            return result;
        }

        lock (_syncLock)
        {
            // 1. Save to App_Data/idash_license.json
            try
            {
                var storageObj = new
                {
                    AppliedUtc = DateTime.UtcNow.ToString("o"),
                    RawKey     = keyString.Trim(),
                    Payload    = result.Payload
                };

                string json = new JavaScriptSerializer().Serialize(storageObj);
                File.WriteAllText(LicenseFilePath, json, Encoding.UTF8);
            }
            catch (Exception ex)
            {
                result.IsValid      = false;
                result.StatusReason = "Failed to save license file to disk: " + ex.Message;
                return result;
            }

            // 2. Save backup to database (dbo.idash_license) if table exists or can be created
            TrySaveLicenseToDatabase(keyString.Trim(), result.Payload);

            // 3. Invalidate cache
            _cachedResult   = result;
            _lastCacheCheck = DateTime.UtcNow;
        }

        return result;
    }

    // -------------------------------------------------------------------
    // Persistence Helpers
    // -------------------------------------------------------------------
    private static string LoadStoredKey()
    {
        // 1. Try file
        if (File.Exists(LicenseFilePath))
        {
            try
            {
                string json = File.ReadAllText(LicenseFilePath, Encoding.UTF8);
                var dict = new JavaScriptSerializer().Deserialize<Dictionary<string, object>>(json);
                if (dict != null && dict.ContainsKey("RawKey"))
                {
                    return Convert.ToString(dict["RawKey"]);
                }
            }
            catch {}
        }

        // 2. Try database
        string dbKey = TryLoadLicenseFromDatabase();
        if (!string.IsNullOrEmpty(dbKey))
        {
            // Sync back to file
            try
            {
                var val = ValidateLicense(dbKey);
                if (val.IsValid)
                {
                    var storageObj = new { AppliedUtc = DateTime.UtcNow.ToString("o"), RawKey = dbKey, Payload = val.Payload };
                    File.WriteAllText(LicenseFilePath, new JavaScriptSerializer().Serialize(storageObj), Encoding.UTF8);
                }
            }
            catch {}
            return dbKey;
        }

        return null;
    }

    private static void TrySaveLicenseToDatabase(string keyString, IdashLicensePayload payload)
    {
        try
        {
            string cs = GetConnectionString();
            if (string.IsNullOrEmpty(cs)) return;

            using (var cn = new SqlConnection(cs))
            {
                cn.Open();
                string sql = @"
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'idash_license')
BEGIN
    CREATE TABLE dbo.idash_license (
        id INT IDENTITY(1,1) PRIMARY KEY,
        licensekey NVARCHAR(MAX) NOT NULL,
        customer NVARCHAR(255) NULL,
        sitename NVARCHAR(255) NULL,
        stationnumber NVARCHAR(50) NULL,
        applieddate DATETIME NOT NULL DEFAULT GETUTCDATE()
    );
END

IF EXISTS (SELECT 1 FROM dbo.idash_license)
    UPDATE dbo.idash_license SET licensekey = @key, customer = @cust, sitename = @site, stationnumber = @station, applieddate = GETUTCDATE();
ELSE
    INSERT INTO dbo.idash_license (licensekey, customer, sitename, stationnumber, applieddate)
    VALUES (@key, @cust, @site, @station, GETUTCDATE());
";
                using (var cmd = new SqlCommand(sql, cn))
                {
                    cmd.Parameters.AddWithValue("@key", keyString);
                    cmd.Parameters.AddWithValue("@cust", (object)payload.Customer ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@site", (object)payload.SiteName ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@station", (object)payload.StationNumber ?? DBNull.Value);
                    cmd.ExecuteNonQuery();
                }
            }
        }
        catch
        {
            // Database sync is non-blocking fallback
        }
    }

    private static string TryLoadLicenseFromDatabase()
    {
        try
        {
            string cs = GetConnectionString();
            if (string.IsNullOrEmpty(cs)) return null;

            using (var cn = new SqlConnection(cs))
            {
                cn.Open();
                string sql = "IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'idash_license') SELECT TOP 1 licensekey FROM dbo.idash_license;";
                using (var cmd = new SqlCommand(sql, cn))
                {
                    object obj = cmd.ExecuteScalar();
                    if (obj != null && obj != DBNull.Value) return Convert.ToString(obj);
                }
            }
        }
        catch {}
        return null;
    }

    private static string GetConnectionString()
    {
        try
        {
            if (System.Configuration.ConfigurationManager.ConnectionStrings["iDash"] != null)
                return System.Configuration.ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
            if (System.Configuration.ConfigurationManager.ConnectionStrings["iDash"] != null)
                return System.Configuration.ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
        }
        catch {}
        return "Server=localhost\\sqlexpress;Database=iDash;User Id=iDashDBAdmin;Password=iDashDBAdmin;Encrypt=False;TrustServerCertificate=True;";
    }

    // -------------------------------------------------------------------
    // Anti-Tamper Clock Verification
    // -------------------------------------------------------------------
    private static bool CheckSystemClockIntegrity(out string error)
    {
        error = null;
        try
        {
            string stateFile = ClockStateFilePath;
            DateTime nowUtc = DateTime.UtcNow;

            if (File.Exists(stateFile))
            {
                string txt = File.ReadAllText(stateFile).Trim();
                long ticks;
                if (long.TryParse(txt, out ticks))
                {
                    DateTime lastUtc = new DateTime(ticks, DateTimeKind.Utc);
                    // If current clock is more than 24 hours in the past compared to last recorded time, flag rollback
                    if (nowUtc < lastUtc.AddHours(-24))
                    {
                        error = string.Format("System clock rollback detected! Last recorded system time was {0:yyyy-MM-dd HH:mm:ss} UTC, but current time is {1:yyyy-MM-dd HH:mm:ss} UTC. Please adjust your clock.", lastUtc, nowUtc);
                        return false;
                    }
                }
            }

            // Save latest observed time
            File.WriteAllText(stateFile, nowUtc.Ticks.ToString());
        }
        catch {}

        return true;
    }
}

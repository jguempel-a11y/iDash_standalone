using System;
using System.Web;

/// <summary>
/// HTTP Module that auto-starts the AntennaLocationService.
/// Calls EnsureStarted on every request so the MQTT thread
/// auto-recovers after IIS app pool recycles or thread aborts.
/// </summary>
public class AntennaServiceStartupModule : IHttpModule
{
    public void Init(HttpApplication context)
    {
        context.BeginRequest += OnBeginRequest;
    }

    private void OnBeginRequest(object sender, EventArgs e)
    {
        try
        {
            AntennaLocationService.EnsureStarted();
        }
        catch { }
    }

    public void Dispose() { }
}

﻿using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace function_app_demo;

public class Function1
{
    private readonly ILogger<Function1> _logger;

    public Function1(ILogger<Function1> logger)
    {
        _logger = logger;
    }

    [Function("Function1")]
    public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");
        return new OkObjectResult("Welcome to Azure Functions!");
    }

    [Function("HealthCheck")]
    public IActionResult HealthCheck([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequest req)
    {
        _logger.LogInformation("Health check endpoint hit.");
        return new OkObjectResult("Healthy");
    }
}

using System.Reflection;
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}



app.UseHttpsRedirection();


// Endpoint de “prueba de vida”
app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        status = "ok",
        timestampUtc = DateTime.UtcNow
    });
}).WithName("health")
.WithOpenApi();

app.MapGet("/version", () =>
{
    var version = Environment.GetEnvironmentVariable("APP_VERSION") ;
    return Results.Ok(new
    {
        version = version ?? Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "unknown",
        timestampUtc = DateTime.UtcNow
    });
}).WithName("version")
.WithOpenApi();


app.Run();



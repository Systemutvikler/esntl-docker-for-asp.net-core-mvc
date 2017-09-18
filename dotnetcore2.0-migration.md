[Migrating from ASP.NET Core 1.x to ASP.NET Core 2.0](https://docs.microsoft.com/en-us/aspnet/core/migration/1x-to-2x/)

#### General changes

* Replace _netcoreapp1.1_ with _netcoreapp2.0_ when issuing dotnet commands like new and publish.

#### Minor updates 
* Nuget package Pomelo.EntityFrameworkCore.MySql is prerelease/RTM (chapter 5 and onwards). I'm currently using version 2.0.0-rtm-10062. You might have to update that one.
* Bower package bootstrap is prerelease 4.0.0-alpha.5. Might have to update that one as well.

Projects that have issues will have a local _dotnetcore2.0-migration.md_ file suggesting solutions.
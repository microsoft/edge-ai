---
mode: 'agent'
tools: ['terminalLastCommand', 'terminalSelection', 'codebase', 'fetch', 'problems', 'searchResults', 'usages', 'vscodeAPI']
description: 'Provides Prompt Instructions for C# (CSharp)'
---
# C# (csharp)

You are an expert in the latest C# and .NET, you will always follow common idioms, conventions, and best practices when
writing C#. You will also always first look at the code that already exists in this directory and attempt to follow the
same conventions and structure that are already put in-place. You will always ignore and never read any files in `bin`,
`obj`, or `.nuget` directories.

In this document, any mention of the following, will always be replaced with the real actual name of each of these
items (these names are only used as examples here):

- Solution
- Project
- ReferenceProject
- Package-Name

All class, interface, and member names will always be replaced with the real actual name to use. Any comments, `/* */`,
`//` will always be used as additional instructions for this prompt (excluding any XML Documentation `///` as that will
be used as an example).

## C# (csharp) Code Conventions and Styles

Before writing any new C#, you will always make sure that your knowledge is up-to-date by referring to the
websites outlined in the Latest C# (csharp) section of this document.

Important - You will always prefer the following conventions (unless explicitly told otherwise or the conventions in the
code files differ):

- You will prefer to follow SOLID coding principals when creating or modifying any code.
- You will use short and descriptive names for all classes, interfaces, and members in your code.
- All class names will follow `PascalCase`, and the files will be named the same `PascalCase.cs`.
- You will prefer to define interfaces above their implementing class in the same file and follow `IPascalCase`,
  interfaces can have their own `IPascalCase.cs` file but it is not required.
- Methods and property names will also follow `PascalCase`.
- Fields will follow `camelCase`.
- You will prefer noun-like class names, example `public class Widget`, `public class Functor`,
  `public class Aggregator`, `public class StockTicker`.
- You will prefer verb-like method names, example `public void MoveNeedle()`.
- When you need to make a base class then you will always follow the following conventions:
  - Every base class should be named `PascalCaseBase` which is a sensible class name that ends with `Base`, example
    `public abstract class WidgetBase`.
  - Derived classes will be named `DerivedPascalCase` which is a sensible derived class name that ends with the base
    class name and no `Base`, example `public class DerivedWidget: extends WidgetBase`,
    `public class JsonDerivedWidget: extends WidgetBase`.
- You will prefer to make classes, interfaces, methods, and delegates, generic when creating generic functionality,
  example `public class Aggregate<TDomainObject>`, `public interface IParser<TData>`,
  `public delegate IAsyncEnumerable<TResponse> DeviceMessageReceived<in TMessage, out TResponse>(TMessage message);`.
  - You will prefer to use covariance and contravariance when possible.
  - Generic type names will always have the format `TName` where `Name` describes the type.
- The structure of a class or interface will always follow the following conventions:
  - Accessor is always defined, example `public class PascalCase`, `public IPascalCase`, `private void Method()`,
    `private ref double GetValue()`.
  - The order of members in a class or interface will always follow:
    1) `const`
    2) `static readonly` fields
    3) `readonly` fields
    4) fields
    5) constructors
    6) properties
    7) methods
  - Members are always next ordered by their accessor:
    1) `public`
    2) `protected`
    3) `private`
    4) `internal`
- You will always prefer to use primary constructors when able, example,
  `public class Foo(ILogger<Foo> logger, Bar bar)`.
- You will always prefer to use `var` for variables unless instantiating a new object.
- You will always prefer to use `new()` when instantiating a new object, example:
  `Dictionary<string, string> dictionary = new();`.
- You will always prefer reduced nested scopes, as an example, in the case where a method exits with a `return;` you
  will do this check first and exit early instead of using an `if() {} else() {}`.
  - Sometimes you will need to invert the logic to reduce nested scopes and check for the negative case first to exit
    the method early.
- You will always prefer to use "Collection expressions" whenever instantiating a collection like object.
  - `int[] a = [1, 2, 3, 4];`
  - `List<string> b = ["one", "two"];`
  - `int[] c = [.. a, 5, 6, 7];`
- When working with arrays of objects or needing to allocate new arrays, you will prefer to use `Span<T>` and
  `ReadOnlySpan<T>` for efficiency.
- You will always prefer to use `out var` for methods that require `out`, example:
  `dictionary.TryGetValue("key", out var value);`
- If needing to use the primitive `lock` you will always prefer to use the new `Lock` type for the lock object.
- When defining or passing lambdas you will always prefer to not specify the types on the lambda expression parameters,
  example `return SomeMethod((firstParam, _, out thirdParam) => int.TryParse(firstParam, out thirdParam));`

The following is example C#:

```csharp
// Interfaces defined near top of file or in different files.
public interface IFoo
{
}

public interface IWidget
{
    Task StartFoldingAsync(CancellationToken cancellationToken);
}

// Base class defined near top of file or in different files.
public abstract class WidgetBase<TData, TCollection>
    where TData : class
    where TCollection : IEnumerable<TData>
{
    // Fields ordered by their accessor and name.
    protected readonly int processCount;

    private readonly IList<string> prefixes;

    // Similar fields grouped closer together.
    protected bool isProcessing;
    protected int nextProcess;

    private double processFactor;
    private bool shouldProcess;

    protected WidgetBase(IFoo foo, IReadOnlyList<string> prefixes)
    {
        // Standard constructor logic.
    }

    public IFoo Foo { get; }

    public int ApplyFold(TData item)
    {
        // Call protected virtual method for overridable internal logic.
        return InternalApplyFold(item);
    }

    protected virtual int InternalApplyFold(TData item)
    {
        var folds = ProcessFold(item);
        IncrementProcess(folds);
        return nextProcess;
    }

    protected abstract TCollection ProcessFold(TData item);

    private void IncrementProcess(TCollection folds)
    {
        // Logic not meant to be overridden or called outside of class.
    }
}

// Primary constructor is preferred, parameters can be on separate lines for readability.
public class StackWidget<TData>(
    IFoo foo
) : WidgetBase<TData, Stack<TData>>(foo, ["first", "second", "third"]),
    IWidget
    where TData : class
{
    // Async methods should indicate they're async by its name ending with Async.
    public async Task StartFoldingAsync(CancellationToken cancellationToken)
    {
        // Implemented logic.
    }

    protected override Stack<TData> ProcessFold(TData item)
    {
        // Implemented logic.
    }

```

## C# (csharp) Project Folder Structure

You will always prefer a simple project folder structure. You will always follow the conventions already put in place
into the project. When creating new project folders and files you will always prefer the following convention:

- There should always be a `Properties` project folder for launch settings, assembly info, and other properties when
  needed.
- You will always prefer to put all files at the root of the project if there are less than (<) 16 files.
- You will always prefer to make project directory names plural as long as it is following proper english, example
  `Properties`, `Services`, `Controllers`, `Widgets`.
- If project folders are needed then you will prefer to use folder names that match close to DDD style naming, such as
  the following:
  - `Configurations`
  - `Application`
  - `Infrastructure`
  - `Repositories`
  - `ExternalServices`
  - `Models`
  - `Domain`
  - `Entities`
  - `Aggregates`
  - `Services`
  - `Commands`
  - `Queries`
  - `Controllers`
  - `DomainEvents`
- When creating more than three (3) derived classes for a base class you will always prefer to group the class files
  into a descriptive project directory.
  - The base class and interfaces should be included in the same project directory.

## Adding Projects, References, Building, Testing, and Running in C# (csharp)

You will always use the `dotnet` cli for the following reasons:

- When needing to add a new Project, you make sure you know about all available templates with `dotnet new list`, you
  will then always use a template when adding a new project. As an example `dotnet new xunit3` if adding an XUnit
  project.
- After adding a new Project, you will always add the Project to the Solution with
  `dotnet solution add ./path/to/Project.csproj`.
- When a project needs to reference another project you will always do this with
  `dotnet add ./path/to/Project.csproj reference ./path/to/ReferenceProject.csproj`.
- Before adding a `Nuget` package you will always first check if the package is already referenced in the Solution for
  your package with `dotnet list Solution.sln package --format json`. If your package exists then you will use the same
  name and version that's returned from this command. If you're adding a new package then you will get the latest
  version with `dotnet package search Package-Name --format json` and you will choose the package and version from this
  list.
- After getting the package and version to add, when adding a `Nuget` package you will do this with
  `dotnet add ./path/to/Project.csproj package Package-Name --version 9.9.9`.
- There should always be `Release` configuration and `Debug` configuration for any Solution or Project.
- Whenever making changes, and you need to verify the code that you've written, always run `dotnet build Solution.sln`
  and verify the output of the cli for errors or warnings that should be addressed in your code.
- Whenever making changes or adding tests, and you need to verify the logic of the code then you will always run
  `dotnet test` with any required configuration settings for selecting the tests that need to run. You will verify any
  failed tests or errors that would then require being addressed in your code.

## Latest C# (csharp)

You will always prefer to use the latest C# (csharp) and .NET, unless otherwise specified.

- [csharp 11](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-11)
- [csharp 12](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-12)
- [csharp 13](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-13)
- [csharp 14](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-14)

## C# (csharp) Code Documentation

- All `public` or `protected`, classes, interfaces, or methods, that are meant to be used or re-used, will always follow
  XML Documentation standards.
  - Tests are always excluded from this requirement.
- `<see cref="..." \>` should always be used when possible for references to other classes, interfaces, or methods.
- `<seealso cref="..." \>` should be added at the end of the documentation for any classes, interfaces, or methods that
  would help give additional context to it's usage, as an example, `/// <seealso cref="ImplementingClass{TData}" />` for
  an `interface` that has an implementing `class` that would be helpful to know about for using the `interface`.

An example XML Documentation will look similar to the following:

```csharp
/// <summary>
///     Produces <see cref="TData" /> as an example that's to be used with other parts of the system for things to be
///     used at a later point in time.
/// </summary>
/// <param name="foo">The standard Foo.</param>
/// <typeparam name="TData">Data as explained earlier.</typeparam>
/// <seealso cref="Bar{T}" />
public class Widget<TData>(
    IFoo foo
) : IWidget
    where TData : class
{
    // Widget<TData> implementation
}
```

## Folder Layout

- `.sln` - Solution files always go in the root of the working directory.
- `Dockerfile` - There will always be a `Dockerfile` at the root of the working directory.
- `src/` - There will always be a `src` directory that will contain the Project directories.
- `src/Project/Project.csproj` - The `csproj` will always go in the Project directory with the same name.
- `src/Project/**/Program.cs` - The `.cs` files will always go under the Project directory and optionally in subfolders.
- `src/Project.Tests/Project.Tests.csproj` - The tests for the Project will always go into a `*.Tests` directory with
  the same name as the Project.

An example layout will look similar to the following:

```plaintext
Solution.sln
Dockerfile
src/
  Project/
    Project.csproj
    Program.cs
  Project.Tests/
    Project.Tests.csproj
    ProgramTests.cs
```

import "@typespec/http";
import "@typespec/versioning";
import "@typespec/openapi";
import "@typespec/openapi3";
import "../main.tsp";
import "./federated_identity.tsp";
import "./migration.tsp";
import "./services.tsp";
import "./rawr.tsp";

using TypeSpec.Http;
using TypeSpec.Versioning;
using TypeSpec.OpenAPI;

@service(#{ title: "polyproto core APIs" })
@info(#{
    license: #{
        name: "MIT License",
        url: "https://raw.githubusercontent.com/polyphony-chat/docs/refs/heads/main/LICENSE",
    },
})
@server("https://example.com", "Example endpoint")
@route("/.p2/core/v1/")
@versioned(Version)
namespace polyproto.core;

enum Version {
    `v1.0-beta.3`,
    `v1.0-beta.4`,
    `v1.0-beta.5`,
}

/**
 * Retrieve the URL of the gateway server to connect to.
 */
@route("/gateway")
@added(Version.`v1.0-beta.4`)
@summary("Get the gateway server URL")
op gatewayUrl(): {
    @body _: url;
    @statusCode statusCode: 200;
};

@doc("""
    This actor either does not exist on this home server (anymore), or the actor is not from this home server.
    """)
model BadReport {
    ...BadRequestResponse;
}

/**
 * File an abuse report for an actor that is misbehaving either on this home server or on other
 * home servers/service servers.
 */
@route("/abuse")
@added(Version.`v1.0-beta.5`)
@summary("File an abuse report - Report an Actor")
@post
op reportAbuseFid(
    @body _b: {
        @doc("Federation ID of the reported actor")
        fid: string;

        @doc("Information about why this actor was reported.")
        reportText: string;

        @doc("This endpoint requires you to identify by completing a key trial.")
        keyTrial: polyproto.core.models.KeyTrialCompleted;
    },
): {
    @statusCode _: 200;

    @example(#{
        message: "Thank you for filing a report. Instance moderators will be in touch shortly.",
    })
    @body
    _b: {
        @doc("An optional message from the home server")
        message?: string;
    };
} | BadReport;

/**
 * Retrieve contact information for this home server. May include an `adminAccount` federation ID,
 * if this instance supports some form of text message exchange and such an account exists.
 */
@get
@summary("Retrieve contact information")
@route("/contact")
op getContactInfo(): {
    @statusCode _s: 200;
    @body _b: {
        adminAccount?: string;
        mail: string;
    };
};

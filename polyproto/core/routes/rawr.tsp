import "@typespec/http";
import "@typespec/versioning";
import "@typespec/openapi";
import "@typespec/openapi3";
import "../main.tsp";
import "./main.tsp";

using TypeSpec.Http;
using TypeSpec.Versioning;

@route("/resource/")
namespace polyproto.core.Routes.ResourceAddressingWithRelativeRoots {
    @tag("Resource addressing with relative roots - Registration not required")
    namespace Unregistered {
        /**
         * Get information about how much storage you are allowed to use, and see how much storage you
         * are currently using.
         */
        @route("/usage")
        @get
        @added(Version.`v1.0-beta.3`)
        @summary("Retrieve information about your storage usage")
        op getStorageLimitInfo(): {
            @statusCode _s: 200;
            @body _b: {
                @doc("How many bytes of storage you are allowed to upload in total")
                limit: uint64;

                @doc("How many bytes of storage you are currently using")
                used: uint64;
            };
        };

        /**
         * Retrieve a [RawR](https://docs.polyphony.chat/Protocol%20Specifications/core/#731-resource-addressing-with-relative-roots)
         * resource by specifying the ID of the resource.
         * @param rid: Resource Identifier - unique identifier for a resource.
         * @returns
         * - `200`: File found and retrieved.
         * - `308`: URI root has changed.
         * - `401`: Server or resource requires authentication to access this endpoint.
         * - `404`: Separately documented.
         */
        @route("/{rid}")
        @get
        @useAuth(BearerAuth | NoAuth)
        @added(Version.`v1.0-beta.3`)
        @summary("Get resource by resource ID")
        op getResource(@path rid: string): {
            @statusCode _: 200;
            @body body: File;
        } | {
            @statusCode _: 308;

            @header(#{ name: "Location" })
            location: url;
        } | polyproto.models.errors.NotFoundOrForbidden;

        /**
         * Query the server for information about a RawR resource.
         * This route accepts a Bearer token, but public resources may also be queried without
         * specifying a token.
         * @param rid The resource ID of the resource which you'd like to query information of.
         *
         * @returns
         * - `200`: Found, contains resource information
         * - `308`: URI root has changed.
         * - `404`: Separately documented.
         */
        @route("/{rid}/info/")
        @get
        @useAuth(BearerAuth | NoAuth)
        @added(Version.`v1.0-beta.3`)
        @summary("Retrieve information about a RawR resource")
        op getResourceInfos(@path rid: string): {
            @statusCode statusCode: 200;
            @body body: polyproto.core.models.ResourceInformation[];
        } | {
            @statusCode _: 308;

            @header(#{ name: "Location" })
            location: url;
        } | polyproto.models.errors.NotFoundOrForbidden;
    }

    @tag("Resource addressing with relative roots - Registration required")
    @useAuth(BearerAuth)
    namespace Registered {
        /**
         * Upload a [RawR](https://docs.polyphony.chat/Protocol%20Specifications/core/#731-resource-addressing-with-relative-roots)
         * resource to your home server.
         * @param rid: The resource ID of the resource you would like to upload.
         * @param resourceAccessProperties ResourceAccessProperties. See the corresponding schema definition for more information.
         * @param contentLength: The size of the resource in bytes.
         * @param file: The resource itself
         * @returns
         * - `204`: Upload successful.
         * - `403`: Uploading forbidden.
         * - `409`: RID already exists on this server. Choose a different RID.
         * - `411`: `Content-Length` header not specified.
         * - `413`: Resource too large.
         * - `414`: RID too long.
         */
        @route("/{rid}")
        @post
        @added(Version.`v1.0-beta.3`)
        @summary("Upload RawR resource")
        op postResource(
            @path rid: string,

            @header(#{ name: "Content-Length" })
            contentLength: uint64,

            @query
            resourceAccessProperties: polyproto.core.models.ResourceAccessProperties,

            @body file: File,
        ):
            | {
                  @statusCode _: 403;
                  @body reason: "UPLOAD_FORBIDDEN";
              }
            | {
                  @statusCode _: 409;
                  @body reason: "DUPLICATE_RID";
              }
            | {
                  @statusCode _: 411;
                  @body reason: "LENGTH_REQUIRED";
              }
            | {
                  @statusCode _: 413;
                  @body body: {
                      reason: "TOO_LARGE";

                      @doc("The server may tell the client how much more content they are allowed to store, in bytes.")
                      remainingStorageBytes?: uint64;
                  };
              }
            | {
                  @statusCode _: 414;
                  reason: "RID_TOO_LONG";
                  charLimit: uint8 = 64;
              }
            | {
                  @statusCode _: 204;

                  @header(#{ name: "Content-Length" })
                  contentLength: 0;
              };

        @route("/{rid}")
        @delete
        @added(Version.`v1.0-beta.3`)
        @summary("Delete RawR resource")
        op deleteResource(@path rid: string): {
            @statusCode _: 204;
        };

        /**
         * Replace the access properties of a [RawR](https://docs.polyphony.chat/Protocol%20Specifications/core/#731-resource-addressing-with-relative-roots)
         * resource with updated access properties.
         * @param rid The resource ID of the resource which the access properties should be modified of.
         * @param resourceAccessProperties ResourceAccessProperties. See the corresponding schema definition for more information.
         */
        @route("/{rid}")
        @put
        @added(Version.`v1.0-beta.3`)
        @summary("Update RawR resource access properties")
        op modifyResource(
            @path rid: string,

            @body
            resourceAccessProperties: polyproto.core.models.ResourceAccessProperties,
        ): {
            @header(#{ name: "Content-Length" })
            contentLength: 0;

            @statusCode _: 204;
        };

        /**
         * Query the server for a list of resources you've uploaded.
         * @param limit Optional; How many results you'd like to retrieve at maximum. Defaults to `50`.
         * @param sort Whether the list should be sorted in a specific way. Available options are `SizeAsc`, `SizeDesc`, `NewestFirst` and `OldestFirst`.
         */
        @route("/resources")
        @get
        @added(Version.`v1.0-beta.3`)
        @summary("List your uploaded resources")
        op getResourceList(
            @query limit?: uint32 = 50,
            @query sort?: polyproto.core.models.ResourceListSorting,

            @doc("Whether to request content previews for supported file formats")
            @query
            previews?: boolean = false,
        ): {
            @statusCode statusCode: 200;
            @body body: {
                resourceInformation: polyproto.core.models.ResourceInformation;

                @doc("Only present, if `previews` was set to `true` in the request, and if the response contains preview-supported file types.")
                preview?: File;
            }[];
        } | {
            @statusCode _: 204;

            @header(#{ name: "Content-Length" })
            contentLength: 0;
        };
    }
}

// rawr x3

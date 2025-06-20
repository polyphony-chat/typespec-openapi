import "@typespec/rest";
import "@typespec/openapi";
import "@typespec/http";
import "./main.tsp";
import "../main.tsp";

using TypeSpec.Http;
using polyproto.models.errors;

@useAuth(BearerAuth)
namespace polyproto.mls.routes {
  namespace groups {
    /**
     * Create a new MLS group
     */
    @post
    @route("/groups")
    op createGroup(@body keyPackage: KeyPackage): {
      @statusCode _s: 200;
      @body _b: Group;
    };

    /**
     * Get information about an MLS group
     */
    @get
    @route("/groups/{groupId}")
    op getGroup(@path groupId: string): {
      @statusCode _s: 200;
      @body _b: Group;
    } | NotFoundOrForbidden;

    /**
     * Submit a proposal to modify the group
     */
    @post
    @route("/groups/{groupId}/proposals")
    op submitProposal(
      @path groupId: string,
      @body proposal: Proposal,
    ): void | NotFoundOrForbidden;

    /**
     * Submit a commit to apply pending proposals
     */
    @post
    @route("/groups/{groupId}/commits")
    op submitCommit(
      @path groupId: string,
      @body commit: Commit,
    ): Welcome | NotFoundOrForbidden;

    /**
     * Get the latest commit for a group
     */
    @get
    @route("/groups/{groupId}/commits/latest")
    op getLatestCommit(@path groupId: string): Commit | NotFoundOrForbidden;
  }

  namespace members {
    /**
     * Get all group members
     */
    @get
    @summary("Get all group members")
    @route("/groups/{groupId}/members")
    op getMembers(@path groupId: string): GroupMember[] | NotFoundOrForbidden;

    /**
     * Get the current state of a group member
     */
    @get
    @summary("Get a singular group member")
    @route("/groups/{groupId}/members/{memberId}")
    op getMember(
      @path groupId: string,
      @path memberId: string,
    ): GroupMember | NotFoundOrForbidden;

    /**
     * Get all pending proposals for a group
     */
    @get
    @route("/groups/{groupId}/proposals")
    op getProposals(@path groupId: string): Proposal[] | NotFoundOrForbidden;
  }
  namespace keypackages {
    /**
     * Upload KeyPackages to the server, enabling other actors to encrypt messages for you and form
     * groups with you.
     */
    @post
    @route("/keypackages")
    @summary("Upload new KeyPackages")
    op addKeyPackages(@body keyPackages: KeyPackage[]): 200 | {
      @statusCode _s: 400;
      @body _b: {
        @doc("The identifier of a faulty keypackage")
        id: string;

        @doc("A string describing what was wrong with this keypackage")
        reason: string;
      }[];
    } | 413;

    /**
     * Discover KeyPackages for a certain user.
     * Filter (allowelist) by MLS protocol versions, ciphersuites and extensions.
     * */
    @get
    @route("/keypackages/{fid}")
    @summary("Retrieve one or more KeyPackages for a user")
    op discoverKeyPackages(
      @path fid: string,
      @query versions?: string[] = #["1.0"],

      @minItems(1)
      @query
      ciphersuites: string[],

      @query extensions?: string[] = #[],
    ): KeyPackage[] | 404 | 204;
  }
}

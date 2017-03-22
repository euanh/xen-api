let config_mk = "config.mk"

(* Configure script *)
open Cmdliner

let dir name default docv doc =
  let doc = Printf.sprintf "Set the directory for installing %s" doc in
  Arg.(value & opt string default & info [name] ~docv ~doc)

let path name default docv doc =
  let doc = Printf.sprintf "Set the path for %s" doc in
  Arg.(value & opt string default & info [name] ~docv ~doc)

let disable_warn_error =
  let doc = "Disable -warn-error (default is enabled for development)" in
  Arg.(value & flag & info [ "disable-warn-error" ] ~doc)

let varpatchdir = dir "varpatchdir" "/var/patch" "VARPATCHDIR" "hotfixes"
let etcdir = dir "etcdir" "/etc/xensource" "ETCDIR" "configuration files"
let optdir = dir "optdir" "/opt/xensource" "OPTDIR" "system files"
let plugindir = dir "plugindir" "/etc/xapi.d/plugins" "PLUGINDIR" "xapi plugins"
let extensiondir = dir "extensiondir" "/etc/xapi.d/extensions" "PLUGINDIR" "XenAPI extensions"
let hooksdir = dir "hooksdir" "/etc/xapi.d" "HOOKSDIR" "hook scripts"
let inventory = path "inventory" "/etc/xensource-inventory" "INVENTORY" "the inventory file"
let xapiconf = dir "xapiconf" "/etc/xapi.conf" "XAPICONF" "xapi master config file"
let libexecdir = dir "libexecdir" "/opt/xensource/libexec" "LIBEXECDIR" "utility binaries"
let scriptsdir = dir "scriptsdir" "/etc/xensource/scripts" "SCRIPTSDIR" "utility scripts"
let sharedir = dir "sharedir" "/opt/xensource" "SHAREDIR" "shared binary files"
let webdir = dir "webdir" "/opt/xensource/www" "WEBDIR" "html files"
let cluster_stack_root = dir "cluster-stack-root" "/usr/libexec/xapi/cluster-stack" "CLUSTER_STACK_ROOT" "cluster stacks"
let bindir = dir "bindir" "/opt/xensource/bin" "BINDIR" "binaries"
let sbindir = dir "sbindir" "/opt/xensource/bin" "BINDIR" "system binaries"
let udevdir = dir "udevdir" "/etc/udev" "UDEVDIR" "udev scripts"

let info =
  let doc = "Configures a package" in
  Term.info "configure" ~version:"0.1" ~doc

let output_file filename lines =
  let oc = open_out filename in
  let lines = List.map (fun line -> line ^ "\n") lines in
  List.iter (output_string oc) lines;
  close_out oc

let configure
    disable_warn_error
    varpatchdir
    etcdir
    optdir
    plugindir
    extensiondir
    hooksdir
    inventory
    xapiconf
    libexecdir
    scriptsdir
    sharedir
    webdir
    cluster_stack_root
    bindir
    sbindir
    udevdir =

  (* Write config.mk *)
  let vars = [
    "DISABLE_WARN_ERROR", string_of_bool disable_warn_error;
    "VARPATCHDIR", varpatchdir;
    "ETCDIR", etcdir;
    "OPTDIR", optdir;
    "PLUGINDIR", plugindir;
    "EXTENSIONDIR", extensiondir;
    "HOOKSDIR", hooksdir;
    "INVENTORY", inventory;
    "XAPICONF", xapiconf;
    "LIBEXECDIR", libexecdir;
    "SCRIPTSDIR", scriptsdir;
    "SHAREDIR", sharedir;
    "WEBDIR", webdir;
    "CLUSTER_STACK_ROOT", cluster_stack_root;
    "BINDIR", bindir;
    "SBINDIR", sbindir;
    "UDEVDIR", udevdir;
  ] in
  let lines = List.map (fun (k,v) -> Printf.sprintf "%s=%s" k v) vars in
  let export = Printf.sprintf "export %s"
      (vars |> List.map fst |> String.concat " ") in
  let header = [
    "# Warning - this file is autogenerated by the configure script";
    "# Do not edit"
  ] in
  Printf.printf "Configuring with the following parameters\n";
  Printf.printf "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n\n";
  List.iter (fun (k,v) ->
      Printf.printf "%20s = %s\n" (String.lowercase k) v) vars;
  output_file config_mk (header @ lines @ [export])

let configure_t =
  Term.(pure configure $ disable_warn_error $ varpatchdir $ etcdir $
        optdir $ plugindir $ extensiondir $ hooksdir $ inventory $
        xapiconf $ libexecdir $ scriptsdir $ sharedir $ webdir $
        cluster_stack_root $ bindir $ sbindir $ udevdir )

let () =
  match
    Term.eval (configure_t, info)
  with
  | `Error _ -> exit 1
  | _ -> exit 0

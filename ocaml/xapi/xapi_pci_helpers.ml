(*
 * Copyright (C) Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

 module D=Debug.Make(struct let name="xapi_pci_helpers" end)
 open D

type pci_property = {
  id: int;
  name: string;
}

type pci = {
  address: string;
  vendor: pci_property;
  device: pci_property;
  pci_class: pci_property;
  subsystem_vendor: pci_property option;
  subsystem_device: pci_property option;
  related: string list;
}

let get_host_pcis () =
  let from_dump =
    try
      Some (Filename.temp_file "pci" "dump")
    with e ->
      debug "Unable to create tempfile for libcpi dump: %s" (Printexc.to_string e);
      None
  in
  let open Pci in
  with_access ?from_dump (fun access ->
      let devs = get_devices access in
      List.map (fun d ->
          let open Pci_dev in
          let address_of_dev x = Printf.sprintf "%04x:%02x:%02x.%d" x.domain x.bus x.dev x.func in
          let vendor = { id = d.vendor_id; name = lookup_vendor_name access d.vendor_id } in
          let device = { id = d.device_id; name = lookup_device_name access d.vendor_id d.device_id } in
          let (subsystem_vendor, subsystem_device) = match d.subsystem_id with
            | None -> None, None
            | Some (sv_id, sd_id) ->
              let sv_name = lookup_subsystem_vendor_name access sv_id in
              let sd_name = lookup_subsystem_device_name access d.vendor_id d.device_id sv_id sd_id in
              Some { id = sv_id; name = sv_name }, Some { id = sd_id; name = sd_name }
          in
          let pci_class = { id = d.device_class; name = lookup_class_name access d.device_class } in
          let related_devs =
            List.filter (fun d' ->
                let slot x = (x.domain, x.bus, x.dev) in
                slot d' = slot d && d' <> d
              ) devs in
          { address = address_of_dev d;
            vendor; device; subsystem_vendor; subsystem_device; pci_class;
            related = List.map address_of_dev related_devs;
          }
        ) devs
    )

let igd_is_whitelisted ~__context pci =
  let vendor_id = Db.PCI.get_vendor_id ~__context ~self:pci in
  List.mem vendor_id !Xapi_globs.igd_passthru_vendor_whitelist


resource "helm_release" "upload_service" {
  count = local.create_upload ? 1 : 0

  depends_on = [helm_release.groundx_service]

  name       = "${var.upload_internal.service}-cluster"
  namespace  = var.app.namespace
  chart      = "${path.module}/../../../modules/upload/helm_chart"

  values = [
    yamlencode({
      image = var.upload_internal.image
      securityContext = {
        runAsUser  = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1001) : 1001
        runAsGroup = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1001) : 1001
        fsGroup    = local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1001) : 1001
      }
      service = {
        name      = var.upload_internal.service
        namespace = var.app.namespace
        version   = var.upload_internal.version
      }
    })
  ]

  timeout = 1800
}
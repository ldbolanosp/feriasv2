import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { ProtectedRoute } from '@/components/shared/ProtectedRoute'
import { AppErrorBoundary } from '@/components/shared/AppErrorBoundary'
import { LoginPage } from '@/pages/auth/LoginPage'
import { SeleccionFeriaPage } from '@/pages/auth/SeleccionFeriaPage'
import { ConfiguracionPage } from '@/pages/configuracion/ConfiguracionPage'
import { ItemsDiagnosticoPage } from '@/pages/configuracion/ItemsDiagnosticoPage'
import { DashboardPage } from '@/pages/dashboard/DashboardPage'
import { FacturaDetallePage } from '@/pages/facturacion/FacturaDetallePage'
import { FacturacionListPage } from '@/pages/facturacion/FacturacionListPage'
import { FacturacionFormPage } from '@/pages/facturacion/FacturacionFormPage'
import { FeriasPage } from '@/pages/ferias/FeriasPage'
import { InspeccionesPage } from '@/pages/inspecciones/InspeccionesPage'
import { ParqueosPage } from '@/pages/parqueos/ParqueosPage'
import { ParticipantesListPage } from '@/pages/participantes/ParticipantesListPage'
import { ParticipanteFormPage } from '@/pages/participantes/ParticipanteFormPage'
import { ProductosPage } from '@/pages/productos/ProductosPage'
import { SanitariosPage } from '@/pages/sanitarios/SanitariosPage'
import { TarimasPage } from '@/pages/tarimas/TarimasPage'
import { UsuariosPage } from '@/pages/usuarios/UsuariosPage'

export default function App() {
  return (
    <AppErrorBoundary>
      <BrowserRouter>
        <Routes>
          {/* Rutas públicas */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/seleccionar-feria" element={<SeleccionFeriaPage />} />

          {/* Rutas protegidas */}
          <Route
            element={
              <ProtectedRoute>
                <AppLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute permission="dashboard.ver">
                  <DashboardPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/facturacion"
              element={
                <ProtectedRoute permission="facturas.ver">
                  <FacturacionListPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/facturacion/crear"
              element={
                <ProtectedRoute permission="facturas.crear">
                  <FacturacionFormPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/facturacion/:id"
              element={
                <ProtectedRoute permission="facturas.ver">
                  <FacturaDetallePage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/facturacion/:id/editar"
              element={
                <ProtectedRoute permission="facturas.editar">
                  <FacturacionFormPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/parqueos"
              element={
                <ProtectedRoute permission="parqueos.ver">
                  <ParqueosPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/tarimas"
              element={
                <ProtectedRoute permission="tarimas.ver">
                  <TarimasPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/sanitarios"
              element={
                <ProtectedRoute permission="sanitarios.ver">
                  <SanitariosPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/inspecciones"
              element={
                <ProtectedRoute permission="inspecciones.ver">
                  <InspeccionesPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/configuracion"
              element={
                <ProtectedRoute permission="configuracion.editar">
                  <ConfiguracionPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/configuracion/ferias"
              element={
                <ProtectedRoute permission="ferias.ver">
                  <FeriasPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/configuracion/participantes"
              element={
                <ProtectedRoute permission="participantes.ver">
                  <ParticipantesListPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/configuracion/participantes/crear"
              element={
                <ProtectedRoute permission="participantes.crear">
                  <ParticipanteFormPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/configuracion/participantes/:id/editar"
              element={
                <ProtectedRoute permission="participantes.editar">
                  <ParticipanteFormPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/configuracion/productos"
              element={
                <ProtectedRoute permission="productos.ver">
                  <ProductosPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/configuracion/items-diagnostico"
              element={
                <ProtectedRoute permission="configuracion.ver">
                  <ItemsDiagnosticoPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/configuracion/usuarios"
              element={
                <ProtectedRoute permission="usuarios.ver">
                  <UsuariosPage />
                </ProtectedRoute>
              }
            />
          </Route>

          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </AppErrorBoundary>
  )
}

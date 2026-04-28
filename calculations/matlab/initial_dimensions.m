%% initial_dimensions.m
% Computes and verifies all initial sizing parameters for the Twin-Tilt-Motor VTOL.
% Reference document: docs/Initial_Dimensions.md
% All quantities in SI units: m, m^2, N, N/m^2, m/s.

clc; clear;

% =========================================================================
%% INPUT PARAMETERS (independent / primary values set by the designer)
% =========================================================================

% --- Environment ---
g      = 9.81;    % [m/s^2]  gravitational acceleration
rho    = 1.225;   % [kg/m^3] ISA sea-level air density
CL_max = 1.3;     % [-]      maximum lift coefficient (assumed, NACA 4412 flap-off)

% --- Main Wing ---
MTOW  = 2.0;      % [kg]   maximum take-off mass
b     = 1.400;    % [m]    wingspan
c_r   = 0.240;    % [m]    root chord
c_t   = 0.160;    % [m]    tip chord

% --- Horizontal Stabilizer ---
l_H      = 0.800; % [m]  tail arm (distance from wing MAC/4 to HT AC)
V_H      = 0.5;   % [-]  horizontal tail volume coefficient
lambda_H = 0.7;   % [-]  taper ratio
AR_H     = 5;     % [-]  aspect ratio

% --- Vertical Stabilizer ---
l_V      = 0.800; % [m]  tail arm (same as l_H for this configuration)
V_V      = 0.035; % [-]  vertical tail volume coefficient
lambda_V = 0.7;   % [-]  taper ratio
AR_V     = 1.5;   % [-]  aspect ratio

% =========================================================================
%% MAIN WING  (derived / secondary parameters)
% =========================================================================

S      = (b / 2) * (c_r + c_t);                           % [m^2] trapezoidal area
AR     = b^2 / S;                                          % [-]   aspect ratio
lambda = c_t / c_r;                                        % [-]   taper ratio

% Mean aerodynamic chord (trapezoid formula)
MAC    = (2/3) * c_r * (1 + lambda + lambda^2) / (1 + lambda);  % [m]

% Aerodynamic / performance quantities
W  = MTOW * g;          % [N]      weight
WS = W / S;             % [N/m^2]  wing loading
V_stall = sqrt(2 * W / (rho * S * CL_max));  % [m/s] stall speed

% =========================================================================
%% HORIZONTAL STABILIZER  (derived from wing geometry + tail parameters)
% =========================================================================

S_H   = V_H * S * MAC / l_H;                              % [m^2]
b_H   = sqrt(AR_H * S_H);                                 % [m]
c_r_H = 2 * S_H / (b_H * (1 + lambda_H));                 % [m]
c_t_H = lambda_H * c_r_H;                                 % [m]
MAC_H = (2/3) * c_r_H * (1 + lambda_H + lambda_H^2) / (1 + lambda_H);  % [m]

% =========================================================================
%% VERTICAL STABILIZER  (derived from wing geometry + tail parameters)
% =========================================================================

S_V   = V_V * S * b / l_V;                                % [m^2]
b_V   = sqrt(AR_V * S_V);                                 % [m]
c_r_V = 2 * S_V / (b_V * (1 + lambda_V));                 % [m]
c_t_V = lambda_V * c_r_V;                                 % [m]
MAC_V = (2/3) * c_r_V * (1 + lambda_V + lambda_V^2) / (1 + lambda_V);  % [m]

% =========================================================================
%% DOCUMENT REFERENCE VALUES  (from docs/Initial_Dimensions.md)
% =========================================================================

S_doc     = 0.2800;   % [m^2]
AR_doc    = 7;        % [-]
MAC_doc   = 0.2000;   % [m]

S_H_doc   = 0.0350;   % [m^2]
b_H_doc   = 0.4180;   % [m]
c_r_H_doc = 0.0990;   % [m]
c_t_H_doc = 0.0690;   % [m]

S_V_doc   = 0.0172;   % [m^2]
b_V_doc   = 0.1600;   % [m]
c_r_V_doc = 0.1260;   % [m]
c_t_V_doc = 0.0880;   % [m]

% =========================================================================
%% CONSOLE OUTPUT
% =========================================================================

sep = repmat('=', 1, 64);
sep2 = repmat('-', 1, 64);

% -------------------------------------------------------------------------
fprintf('\n%s\n', sep);
fprintf('  MAIN WING — Computed Parameters\n');
fprintf('%s\n', sep);
fprintf('  %-28s %10.4f  m^2\n', 'Wing area  S',          S);
fprintf('  %-28s %10.4f  -\n',   'Aspect ratio  AR',      AR);
fprintf('  %-28s %10.4f  -\n',   'Taper ratio  lambda',   lambda);
fprintf('  %-28s %10.4f  m\n',   'MAC',                   MAC);
fprintf('  %-28s %10.4f  N\n',   'Weight  W',             W);
fprintf('  %-28s %10.4f  N/m^2\n','Wing loading  W/S',    WS);
fprintf('  %-28s %10.4f  m/s\n', 'Stall speed  V_stall',  V_stall);

fprintf('\n%s\n', sep2);
fprintf('  Main Wing — Comparison with documented values\n');
fprintf('%s\n', sep2);
fprintf('  %-14s %12s %12s %10s\n', 'Parameter', 'Computed', 'Document', 'Diff %');
fprintf('%s\n', sep2);
print_comparison('S  [m^2]',   S,   S_doc);
print_comparison('AR [-]',     AR,  AR_doc);
print_comparison('MAC [m]',    MAC, MAC_doc);

% -------------------------------------------------------------------------
fprintf('\n%s\n', sep);
fprintf('  HORIZONTAL STABILIZER — Computed Parameters\n');
fprintf('%s\n', sep);
fprintf('  %-28s %10.4f  m^2\n', 'Area  S_H',             S_H);
fprintf('  %-28s %10.4f  m\n',   'Span  b_H',             b_H);
fprintf('  %-28s %10.4f  m\n',   'Root chord  c_r_H',     c_r_H);
fprintf('  %-28s %10.4f  m\n',   'Tip chord  c_t_H',      c_t_H);
fprintf('  %-28s %10.4f  m\n',   'MAC_H',                 MAC_H);
fprintf('  %-28s %10.4f  -\n',   'Taper ratio  lambda_H', lambda_H);
fprintf('  %-28s %10.4f  -\n',   'AR_H',                  AR_H);

fprintf('\n%s\n', sep2);
fprintf('  Horizontal Stabilizer — Comparison with documented values\n');
fprintf('%s\n', sep2);
fprintf('  %-14s %12s %12s %10s\n', 'Parameter', 'Computed', 'Document', 'Diff %');
fprintf('%s\n', sep2);
print_comparison('S_H [m^2]',    S_H,   S_H_doc);
print_comparison('b_H [m]',      b_H,   b_H_doc);
print_comparison('c_r_H [m]',    c_r_H, c_r_H_doc);
print_comparison('c_t_H [m]',    c_t_H, c_t_H_doc);

% -------------------------------------------------------------------------
fprintf('\n%s\n', sep);
fprintf('  VERTICAL STABILIZER — Computed Parameters\n');
fprintf('%s\n', sep);
fprintf('  %-28s %10.4f  m^2\n', 'Area  S_V',             S_V);
fprintf('  %-28s %10.4f  m\n',   'Span  b_V',             b_V);
fprintf('  %-28s %10.4f  m\n',   'Root chord  c_r_V',     c_r_V);
fprintf('  %-28s %10.4f  m\n',   'Tip chord  c_t_V',      c_t_V);
fprintf('  %-28s %10.4f  m\n',   'MAC_V',                 MAC_V);
fprintf('  %-28s %10.4f  -\n',   'Taper ratio  lambda_V', lambda_V);
fprintf('  %-28s %10.4f  -\n',   'AR_V',                  AR_V);

fprintf('\n%s\n', sep2);
fprintf('  Vertical Stabilizer — Comparison with documented values\n');
fprintf('%s\n', sep2);
fprintf('  %-14s %12s %12s %10s\n', 'Parameter', 'Computed', 'Document', 'Diff %');
fprintf('%s\n', sep2);
print_comparison('S_V [m^2]',    S_V,   S_V_doc);
print_comparison('b_V [m]',      b_V,   b_V_doc);
print_comparison('c_r_V [m]',    c_r_V, c_r_V_doc);
print_comparison('c_t_V [m]',    c_t_V, c_t_V_doc);

% -------------------------------------------------------------------------
fprintf('\n%s\n', sep);
fprintf('  PERFORMANCE SUMMARY\n');
fprintf('%s\n', sep);
fprintf('  %-28s %10.4f  N/m^2\n', 'Wing loading  W/S',       WS);
fprintf('  %-28s %10.4f  m/s\n',   'Stall speed (CL_max=1.3)', V_stall);
fprintf('  %-28s %10.4f  m/s\n',   'Stall speed (km/h)',       V_stall * 3.6);
fprintf('%s\n\n', sep);

% =========================================================================
%% LOCAL FUNCTION
% =========================================================================

function print_comparison(label, computed, doc_val)
    % Prints one comparison row; flags differences exceeding 2%.
    diff_pct = (computed - doc_val) / doc_val * 100;
    flag = '';
    if abs(diff_pct) > 2.0
        flag = '  [NOTE]';
    end
    fprintf('  %-14s %12.5f %12.5f %9.2f%%%s\n', ...
            label, computed, doc_val, diff_pct, flag);
end

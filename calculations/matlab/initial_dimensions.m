%% initial_dimensions.m
% Parametric initial sizing calculator for the Twin-Tilt-Motor VTOL.
%
% Usage:
%   Open this file, edit the USER INPUT PARAMETERS section below, then run:
%   initial_dimensions
%
% The main wing is sized from MTOW, wing loading W/S, aspect ratio, and
% taper ratio. The horizontal and vertical stabilizers are then sized from
% tail volume coefficients, tail arms, aspect ratios, and taper ratios.
%
% The reference document uses "MAC" as S/b = 0.2 m for the initial sizing
% tail-arm relation l = 4 MAC. The script preserves that documented sizing
% convention as wing.MAC and also reports the standard trapezoidal
% aerodynamic MAC as wing.aerodynamicMAC.
%
% Units:
%   Mass: kg
%   Force: N
%   Length: m
%   Area: m^2
%   Wing loading W/S: N/m^2

clc; clear;

% =========================================================================
%% USER INPUT PARAMETERS
% =========================================================================
% Change values in this block for a new aircraft sizing case.

% --- Environment ---
inputs.g = 9.81;                 % [m/s^2] gravitational acceleration
inputs.rho = 1.225;              % [kg/m^3] air density
inputs.CL_max = 1.3;             % [-] maximum lift coefficient

% --- Main Wing ---
inputs.MTOW = 2.0;               % [kg] maximum take-off mass
inputs.wingLoading = 65;  % [N/m^2] W/S
inputs.mainWing.AR = 7.0;        % [-] aspect ratio
inputs.mainWing.taperRatio = 0.67;  % [-] taper ratio, c_t / c_r

% --- Horizontal Stabilizer ---
inputs.horizontalStabilizer.volumeCoefficient = 0.55;  % [-] V_H
inputs.horizontalStabilizer.tailArmMAC = 4.0;         % [-] l_H / MAC
% inputs.horizontalStabilizer.tailArm = 0.800;        % [m] optional direct l_H
inputs.horizontalStabilizer.AR = 5.0;                 % [-] AR_H
inputs.horizontalStabilizer.taperRatio = 0.7;         % [-] c_t_H / c_r_H

% --- Vertical Stabilizer ---
inputs.verticalStabilizer.volumeCoefficient = 0.035;  % [-] V_V
inputs.verticalStabilizer.tailArmMAC = 4.0;           % [-] l_V / MAC
% inputs.verticalStabilizer.tailArm = 0.800;          % [m] optional direct l_V
inputs.verticalStabilizer.AR = 1.5;                   % [-] AR_V
inputs.verticalStabilizer.taperRatio = 0.7;           % [-] c_t_V / c_r_V

% Set this to false when you are no longer comparing against the documented
% baseline values in docs/Initial_Dimensions.md.
runDocumentVerification = true;

% =========================================================================
%% CALCULATION
% =========================================================================

inputs = apply_defaults(inputs);
validate_inputs(inputs);

results.inputs = inputs;
results.mainWing = size_main_wing(inputs);
results.horizontalStabilizer = size_horizontal_stabilizer(inputs, results.mainWing);
results.verticalStabilizer = size_vertical_stabilizer(inputs, results.mainWing);
results.performance = size_performance(inputs, results.mainWing);

print_report(results);
if runDocumentVerification
    validate_against_document(results);
end

function inputs = apply_defaults(inputs)
    inputs = set_default(inputs, 'g', 9.81);
    inputs = set_default(inputs, 'rho', 1.225);
    inputs = set_default(inputs, 'CL_max', 1.3);

    if ~isfield(inputs, 'mainWing') || isempty(inputs.mainWing)
        inputs.mainWing = struct();
    end
    if ~isfield(inputs, 'horizontalStabilizer') || isempty(inputs.horizontalStabilizer)
        inputs.horizontalStabilizer = struct();
    end
    if ~isfield(inputs, 'verticalStabilizer') || isempty(inputs.verticalStabilizer)
        inputs.verticalStabilizer = struct();
    end

    inputs.mainWing = set_default(inputs.mainWing, 'taperRatio', 160 / 240);

    inputs.horizontalStabilizer = set_default(inputs.horizontalStabilizer, 'volumeCoefficient', 0.5);
    inputs.horizontalStabilizer = set_default(inputs.horizontalStabilizer, 'tailArmMAC', 4.0);
    inputs.horizontalStabilizer = set_default(inputs.horizontalStabilizer, 'AR', 5.0);
    inputs.horizontalStabilizer = set_default(inputs.horizontalStabilizer, 'taperRatio', 0.7);

    inputs.verticalStabilizer = set_default(inputs.verticalStabilizer, 'volumeCoefficient', 0.035);
    inputs.verticalStabilizer = set_default(inputs.verticalStabilizer, 'tailArmMAC', 4.0);
    inputs.verticalStabilizer = set_default(inputs.verticalStabilizer, 'AR', 1.5);
    inputs.verticalStabilizer = set_default(inputs.verticalStabilizer, 'taperRatio', 0.7);
end

function s = set_default(s, name, value)
    if ~isfield(s, name) || isempty(s.(name))
        s.(name) = value;
    end
end

function validate_inputs(inputs)
    require_positive(inputs.MTOW, 'inputs.MTOW');
    require_positive(inputs.wingLoading, 'inputs.wingLoading');
    require_positive(inputs.g, 'inputs.g');
    require_positive(inputs.rho, 'inputs.rho');
    require_positive(inputs.CL_max, 'inputs.CL_max');

    require_positive(inputs.mainWing.AR, 'inputs.mainWing.AR');
    require_taper_ratio(inputs.mainWing.taperRatio, 'inputs.mainWing.taperRatio');

    require_positive(inputs.horizontalStabilizer.volumeCoefficient, ...
        'inputs.horizontalStabilizer.volumeCoefficient');
    require_positive(resolve_tail_arm(inputs.horizontalStabilizer, 1.0), ...
        'inputs.horizontalStabilizer.tailArm or tailArmMAC');
    require_positive(inputs.horizontalStabilizer.AR, 'inputs.horizontalStabilizer.AR');
    require_taper_ratio(inputs.horizontalStabilizer.taperRatio, ...
        'inputs.horizontalStabilizer.taperRatio');

    require_positive(inputs.verticalStabilizer.volumeCoefficient, ...
        'inputs.verticalStabilizer.volumeCoefficient');
    require_positive(resolve_tail_arm(inputs.verticalStabilizer, 1.0), ...
        'inputs.verticalStabilizer.tailArm or tailArmMAC');
    require_positive(inputs.verticalStabilizer.AR, 'inputs.verticalStabilizer.AR');
    require_taper_ratio(inputs.verticalStabilizer.taperRatio, ...
        'inputs.verticalStabilizer.taperRatio');
end

function require_positive(value, name)
    if ~isscalar(value) || ~isnumeric(value) || value <= 0
        error('initial_dimensions:InvalidInput', '%s must be a positive scalar.', name);
    end
end

function require_taper_ratio(value, name)
    require_positive(value, name);
    if value > 1
        error('initial_dimensions:InvalidInput', '%s should be <= 1 for a tapered planform.', name);
    end
end

function wing = size_main_wing(inputs)
    wing.MTOW = inputs.MTOW;
    wing.weight = inputs.MTOW * inputs.g;
    wing.wingLoading = inputs.wingLoading;
    wing.area = wing.weight / inputs.wingLoading;
    wing.AR = inputs.mainWing.AR;
    wing.taperRatio = inputs.mainWing.taperRatio;
    wing.span = sqrt(wing.AR * wing.area);
    wing.rootChord = 2 * wing.area / (wing.span * (1 + wing.taperRatio));
    wing.tipChord = wing.taperRatio * wing.rootChord;
    wing.MAC = wing.area / wing.span;
    wing.aerodynamicMAC = trapezoid_mac(wing.rootChord, wing.taperRatio);
end

function tail = size_horizontal_stabilizer(inputs, wing)
    cfg = inputs.horizontalStabilizer;
    tail.volumeCoefficient = cfg.volumeCoefficient;
    tail.tailArm = resolve_tail_arm(cfg, wing.MAC);
    tail.tailArmMAC = tail.tailArm / wing.MAC;
    tail.area = tail.volumeCoefficient * wing.area * wing.MAC / tail.tailArm;
    tail.AR = cfg.AR;
    tail.taperRatio = cfg.taperRatio;
    tail.span = sqrt(tail.AR * tail.area);
    tail.rootChord = 2 * tail.area / (tail.span * (1 + tail.taperRatio));
    tail.tipChord = tail.taperRatio * tail.rootChord;
    tail.MAC = trapezoid_mac(tail.rootChord, tail.taperRatio);
end

function tail = size_vertical_stabilizer(inputs, wing)
    cfg = inputs.verticalStabilizer;
    tail.volumeCoefficient = cfg.volumeCoefficient;
    tail.tailArm = resolve_tail_arm(cfg, wing.MAC);
    tail.tailArmMAC = tail.tailArm / wing.MAC;
    tail.area = tail.volumeCoefficient * wing.area * wing.span / tail.tailArm;
    tail.AR = cfg.AR;
    tail.taperRatio = cfg.taperRatio;
    tail.span = sqrt(tail.AR * tail.area);
    tail.rootChord = 2 * tail.area / (tail.span * (1 + tail.taperRatio));
    tail.tipChord = tail.taperRatio * tail.rootChord;
    tail.MAC = trapezoid_mac(tail.rootChord, tail.taperRatio);
end

function perf = size_performance(inputs, wing)
    perf.stallSpeed = sqrt(2 * wing.weight / (inputs.rho * wing.area * inputs.CL_max));
    perf.stallSpeedKmh = perf.stallSpeed * 3.6;
end

function tailArm = resolve_tail_arm(cfg, referenceMAC)
    if isfield(cfg, 'tailArm') && ~isempty(cfg.tailArm)
        tailArm = cfg.tailArm;
    else
        tailArm = cfg.tailArmMAC * referenceMAC;
    end
end

function mac = trapezoid_mac(rootChord, taperRatio)
    mac = (2 / 3) * rootChord * ...
        (1 + taperRatio + taperRatio^2) / (1 + taperRatio);
end

function print_report(results)
    sep = repmat('=', 1, 72);
    sep2 = repmat('-', 1, 72);

    wing = results.mainWing;
    hTail = results.horizontalStabilizer;
    vTail = results.verticalStabilizer;
    perf = results.performance;

    fprintf('\n%s\n', sep);
    fprintf('  MAIN WING - Computed Parameters\n');
    fprintf('%s\n', sep);
    print_value('MTOW', wing.MTOW, 'kg');
    print_value('Weight W', wing.weight, 'N');
    print_value('Wing loading W/S', wing.wingLoading, 'N/m^2');
    print_value('Area S', wing.area, 'm^2');
    print_value('Span b', wing.span, 'm');
    print_value('Aspect ratio AR', wing.AR, '-');
    print_value('Taper ratio lambda', wing.taperRatio, '-');
    print_value('Root chord c_r', wing.rootChord, 'm');
    print_value('Tip chord c_t', wing.tipChord, 'm');
    print_value('MAC used for sizing, S/b', wing.MAC, 'm');
    print_value('Aerodynamic MAC', wing.aerodynamicMAC, 'm');

    fprintf('\n%s\n', sep);
    fprintf('  HORIZONTAL STABILIZER - Computed Parameters\n');
    fprintf('%s\n', sep);
    print_value('Volume coefficient V_H', hTail.volumeCoefficient, '-');
    print_value('Tail arm l_H', hTail.tailArm, 'm');
    print_value('Tail arm / MAC', hTail.tailArmMAC, '-');
    print_value('Area S_H', hTail.area, 'm^2');
    print_value('Span b_H', hTail.span, 'm');
    print_value('Aspect ratio AR_H', hTail.AR, '-');
    print_value('Taper ratio lambda_H', hTail.taperRatio, '-');
    print_value('Root chord c_r_H', hTail.rootChord, 'm');
    print_value('Tip chord c_t_H', hTail.tipChord, 'm');
    print_value('MAC_H', hTail.MAC, 'm');

    fprintf('\n%s\n', sep);
    fprintf('  VERTICAL STABILIZER - Computed Parameters\n');
    fprintf('%s\n', sep);
    print_value('Volume coefficient V_V', vTail.volumeCoefficient, '-');
    print_value('Tail arm l_V', vTail.tailArm, 'm');
    print_value('Tail arm / MAC', vTail.tailArmMAC, '-');
    print_value('Area S_V', vTail.area, 'm^2');
    print_value('Span b_V', vTail.span, 'm');
    print_value('Aspect ratio AR_V', vTail.AR, '-');
    print_value('Taper ratio lambda_V', vTail.taperRatio, '-');
    print_value('Root chord c_r_V', vTail.rootChord, 'm');
    print_value('Tip chord c_t_V', vTail.tipChord, 'm');
    print_value('MAC_V', vTail.MAC, 'm');

    fprintf('\n%s\n', sep);
    fprintf('  PERFORMANCE SUMMARY\n');
    fprintf('%s\n', sep);
    print_value('Stall speed', perf.stallSpeed, 'm/s');
    print_value('Stall speed', perf.stallSpeedKmh, 'km/h');

    fprintf('\n%s\n', sep2);
    fprintf('  Embedded formulas\n');
    fprintf('%s\n', sep2);
    fprintf('  W = MTOW g\n');
    fprintf('  S = W / (W/S)\n');
    fprintf('  b = sqrt(AR S)\n');
    fprintf('  c_r = 2 S / (b (1 + lambda)); c_t = lambda c_r\n');
    fprintf('  MAC_sizing = S / b  (matches docs/Initial_Dimensions.md)\n');
    fprintf('  MAC_aero = (2/3) c_r (1 + lambda + lambda^2) / (1 + lambda)\n');
    fprintf('  S_H = V_H S MAC / l_H\n');
    fprintf('  S_V = V_V S b / l_V\n');
    fprintf('  b_tail = sqrt(AR_tail S_tail)\n');
end

function print_value(label, value, unitText)
    fprintf('  %-32s %12.6f  %s\n', label, value, unitText);
end

function validate_against_document(results)
    doc = documented_reference();
    tolerance = 0.012;

    fprintf('\n%s\n', repmat('-', 1, 72));
    fprintf('  Verification against Initial_Dimensions.md\n');
    fprintf('%s\n', repmat('-', 1, 72));
    fprintf('  %-28s %12s %12s %10s %8s\n', ...
        'Parameter', 'Computed', 'Document', 'Diff %', 'Status');
    fprintf('%s\n', repmat('-', 1, 72));

    maxRelativeError = 0;
    maxRelativeError = max(maxRelativeError, compare_value('Wing area S [m^2]', ...
        results.mainWing.area, doc.mainWing.area, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('Wing span b [m]', ...
        results.mainWing.span, doc.mainWing.span, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('Wing AR [-]', ...
        results.mainWing.AR, doc.mainWing.AR, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('Wing taper [-]', ...
        results.mainWing.taperRatio, doc.mainWing.taperRatio, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('Wing root chord [m]', ...
        results.mainWing.rootChord, doc.mainWing.rootChord, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('Wing tip chord [m]', ...
        results.mainWing.tipChord, doc.mainWing.tipChord, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('Wing MAC [m]', ...
        results.mainWing.MAC, doc.mainWing.MAC, tolerance));

    maxRelativeError = max(maxRelativeError, compare_value('H-tail l_H [m]', ...
        results.horizontalStabilizer.tailArm, doc.horizontalStabilizer.tailArm, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('H-tail S_H [m^2]', ...
        results.horizontalStabilizer.area, doc.horizontalStabilizer.area, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('H-tail b_H [m]', ...
        results.horizontalStabilizer.span, doc.horizontalStabilizer.span, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('H-tail root chord [m]', ...
        results.horizontalStabilizer.rootChord, doc.horizontalStabilizer.rootChord, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('H-tail tip chord [m]', ...
        results.horizontalStabilizer.tipChord, doc.horizontalStabilizer.tipChord, tolerance));

    maxRelativeError = max(maxRelativeError, compare_value('V-tail l_V [m]', ...
        results.verticalStabilizer.tailArm, doc.verticalStabilizer.tailArm, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('V-tail S_V [m^2]', ...
        results.verticalStabilizer.area, doc.verticalStabilizer.area, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('V-tail b_V [m]', ...
        results.verticalStabilizer.span, doc.verticalStabilizer.span, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('V-tail root chord [m]', ...
        results.verticalStabilizer.rootChord, doc.verticalStabilizer.rootChord, tolerance));
    maxRelativeError = max(maxRelativeError, compare_value('V-tail tip chord [m]', ...
        results.verticalStabilizer.tipChord, doc.verticalStabilizer.tipChord, tolerance));

    fprintf('%s\n', repmat('-', 1, 72));
    fprintf('  Maximum relative error: %.3f%%\n', maxRelativeError * 100);
    if maxRelativeError <= tolerance
        fprintf('  Verification result: PASS\n\n');
    else
        fprintf('  Verification result: CHECK VALUES\n\n');
    end
end

function relativeError = compare_value(label, computed, reference, tolerance)
    if reference == 0
        relativeError = abs(computed - reference);
    else
        relativeError = abs((computed - reference) / reference);
    end

    diffPct = 100 * (computed - reference) / reference;
    if relativeError <= tolerance
        status = 'PASS';
    else
        status = 'CHECK';
    end

    fprintf('  %-28s %12.6f %12.6f %9.3f%% %8s\n', ...
        label, computed, reference, diffPct, status);
end

function doc = documented_reference()
    doc.mainWing.MTOW = 2.0;
    doc.mainWing.area = 0.28;
    doc.mainWing.span = 1.4;
    doc.mainWing.AR = 7.0;
    doc.mainWing.taperRatio = 0.67;
    doc.mainWing.rootChord = 0.240;
    doc.mainWing.tipChord = 0.160;
    doc.mainWing.MAC = 0.200;

    doc.horizontalStabilizer.tailArm = 0.800;
    doc.horizontalStabilizer.volumeCoefficient = 0.5;
    doc.horizontalStabilizer.area = 0.035;
    doc.horizontalStabilizer.AR = 5.0;
    doc.horizontalStabilizer.span = 0.418;
    doc.horizontalStabilizer.taperRatio = 0.7;
    doc.horizontalStabilizer.rootChord = 0.099;
    doc.horizontalStabilizer.tipChord = 0.069;

    doc.verticalStabilizer.tailArm = 0.800;
    doc.verticalStabilizer.volumeCoefficient = 0.035;
    doc.verticalStabilizer.area = 0.0172;
    doc.verticalStabilizer.AR = 1.5;
    doc.verticalStabilizer.span = 0.160;
    doc.verticalStabilizer.taperRatio = 0.7;
    doc.verticalStabilizer.rootChord = 0.126;
    doc.verticalStabilizer.tipChord = 0.088;
end
